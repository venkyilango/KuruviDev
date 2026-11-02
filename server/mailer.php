<?php
/**
 * Email delivery for the OTP service.
 *
 * `mail()` is unreliable from a Hostinger preview domain (no MX/SPF/DKIM), so
 * the default is Brevo's HTTP API — it needs no library, no open SMTP port,
 * and lets you send from a single verified address without owning a domain.
 *
 * Switch providers with MAILER in config.php.
 */

/**
 * Sends an HTML email. Returns [ok, detail] so the caller can log why a send
 * failed without leaking that detail to the client.
 *
 * @return array{0:bool,1:string}
 */
function send_email(string $to, string $subject, string $html): array
{
    switch (MAILER) {
        case 'smtp':
            return send_via_smtp($to, $subject, $html);
        case 'brevo':
            return send_via_brevo($to, $subject, $html);
        case 'resend':
            return send_via_resend($to, $subject, $html);
        case 'mail':
        default:
            return send_via_mail($to, $subject, $html);
    }
}

/** PHP's built-in mail(). Fine on a real domain, poor on a preview domain. */
function send_via_mail(string $to, string $subject, string $html): array
{
    $headers = implode("\r\n", [
        'MIME-Version: 1.0',
        'Content-Type: text/html; charset=UTF-8',
        'From: ' . MAIL_FROM_NAME . ' <' . MAIL_FROM . '>',
        'Reply-To: ' . MAIL_FROM,
    ]);

    $ok = @mail($to, $subject, $html, $headers);
    return [$ok, $ok ? 'queued' : 'mail() returned false'];
}

/** Brevo (brevo.com) — free tier 300 emails/day, single-sender verification. */
function send_via_brevo(string $to, string $subject, string $html): array
{
    return post_json(
        'https://api.brevo.com/v3/smtp/email',
        [
            'sender'      => ['name' => MAIL_FROM_NAME, 'email' => MAIL_FROM],
            'to'          => [['email' => $to]],
            'subject'     => $subject,
            'htmlContent' => $html,
        ],
        [
            'accept: application/json',
            'api-key: ' . MAILER_API_KEY,
        ]
    );
}

/** Resend (resend.com) — free tier 3,000 emails/month. */
function send_via_resend(string $to, string $subject, string $html): array
{
    return post_json(
        'https://api.resend.com/emails',
        [
            'from'    => MAIL_FROM_NAME . ' <' . MAIL_FROM . '>',
            'to'      => [$to],
            'subject' => $subject,
            'html'    => $html,
        ],
        ['Authorization: Bearer ' . MAILER_API_KEY]
    );
}

/** Shared JSON POST used by the HTTP providers. */
function post_json(string $url, array $payload, array $headers): array
{
    if (!function_exists('curl_init')) {
        return [false, 'curl extension not available'];
    }

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => json_encode($payload),
        CURLOPT_HTTPHEADER     => array_merge(['Content-Type: application/json'], $headers),
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT        => 20,
        CURLOPT_SSL_VERIFYPEER => true,
    ]);

    $body   = curl_exec($ch);
    $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $err    = curl_error($ch);
    curl_close($ch);

    if ($body === false) {
        return [false, 'curl error: ' . $err];
    }
    if ($status >= 200 && $status < 300) {
        return [true, 'accepted (' . $status . ')'];
    }
    return [false, 'provider returned ' . $status . ': ' . substr((string) $body, 0, 300)];
}

// ---------------------------------------------------------------------------
// SMTP
// ---------------------------------------------------------------------------

/**
 * Direct SMTP, no library. Works with any provider that speaks SMTP AUTH:
 * Hostinger mailboxes, Gmail app passwords, Brevo's relay, Zoho, Mailgun.
 *
 * SMTP_SECURE picks the transport: 'ssl' for implicit TLS (port 465),
 * 'tls' for STARTTLS (port 587), 'none' for an unencrypted localhost relay.
 */
function send_via_smtp(string $to, string $subject, string $html): array
{
    $scheme = SMTP_SECURE === 'ssl' ? 'ssl://' : 'tcp://';

    $ctx = stream_context_create([
        'ssl' => ['verify_peer' => true, 'verify_peer_name' => true, 'SNI_enabled' => true],
    ]);

    $fp = @stream_socket_client(
        $scheme . SMTP_HOST . ':' . SMTP_PORT,
        $errno,
        $errstr,
        SMTP_TIMEOUT,
        STREAM_CLIENT_CONNECT,
        $ctx
    );

    if (!$fp) {
        // Shared hosts often firewall outbound 465/587 to third-party relays.
        return [false, "connect to " . SMTP_HOST . ':' . SMTP_PORT . " failed: $errstr ($errno)"];
    }

    stream_set_timeout($fp, SMTP_TIMEOUT);
    $log = [];

    try {
        smtp_expect($fp, 220, $log);

        $helo = SMTP_HELO !== '' ? SMTP_HELO : (parse_url(SMTP_HOST, PHP_URL_HOST) ?: 'localhost');
        smtp_cmd($fp, "EHLO $helo", 250, $log);

        if (SMTP_SECURE === 'tls') {
            smtp_cmd($fp, 'STARTTLS', 220, $log);
            $ok = @stream_socket_enable_crypto(
                $fp,
                true,
                STREAM_CRYPTO_METHOD_TLS_CLIENT | STREAM_CRYPTO_METHOD_TLSv1_2_CLIENT | STREAM_CRYPTO_METHOD_TLSv1_3_CLIENT
            );
            if ($ok !== true) {
                throw new RuntimeException('STARTTLS handshake failed');
            }
            smtp_cmd($fp, "EHLO $helo", 250, $log); // must re-announce after upgrade
        }

        if (SMTP_USER !== '') {
            smtp_cmd($fp, 'AUTH LOGIN', 334, $log);
            smtp_cmd($fp, base64_encode(SMTP_USER), 334, $log, '[username]');
            smtp_cmd($fp, base64_encode(SMTP_PASS), 235, $log, '[password]');
        }

        smtp_cmd($fp, 'MAIL FROM:<' . MAIL_FROM . '>', 250, $log);
        smtp_cmd($fp, 'RCPT TO:<' . $to . '>', 250, $log);
        smtp_cmd($fp, 'DATA', 354, $log);

        fwrite($fp, smtp_message($to, $subject, $html) . "\r\n.\r\n");
        smtp_expect($fp, 250, $log);

        @fwrite($fp, "QUIT\r\n");
        fclose($fp);

        return [true, 'accepted by ' . SMTP_HOST];
    } catch (RuntimeException $e) {
        @fclose($fp);
        return [false, $e->getMessage()];
    }
}

/** Builds the RFC 5322 message, with dot-stuffing so a line of "." can't end DATA early. */
function smtp_message(string $to, string $subject, string $html): string
{
    $headers = [
        'Date: ' . date(DATE_RFC2822),
        'Message-ID: <' . bin2hex(random_bytes(12)) . '@' . (parse_url(SMTP_HOST, PHP_URL_HOST) ?: SMTP_HOST) . '>',
        'From: ' . smtp_encode_name(MAIL_FROM_NAME) . ' <' . MAIL_FROM . '>',
        'Reply-To: ' . MAIL_FROM,
        'To: <' . $to . '>',
        'Subject: ' . smtp_encode_name($subject),
        'MIME-Version: 1.0',
        'Content-Type: text/html; charset=UTF-8',
        'Content-Transfer-Encoding: 8bit',
    ];

    $body = preg_replace('/^\./m', '..', str_replace(["\r\n", "\r", "\n"], "\r\n", $html));

    return implode("\r\n", $headers) . "\r\n\r\n" . $body;
}

/** RFC 2047 encodes a header value only when it isn't plain ASCII. */
function smtp_encode_name(string $v): string
{
    return preg_match('/[^\x20-\x7E]/', $v) ? '=?UTF-8?B?' . base64_encode($v) . '?=' : $v;
}

/** Sends one command and asserts the reply code. $redact hides credentials from the log. */
function smtp_cmd($fp, string $cmd, int $expect, array &$log, string $redact = ''): string
{
    $log[] = '> ' . ($redact !== '' ? $redact : $cmd);
    fwrite($fp, $cmd . "\r\n");
    return smtp_expect($fp, $expect, $log);
}

/** Reads a (possibly multiline) reply and throws unless it starts with $expect. */
function smtp_expect($fp, int $expect, array &$log): string
{
    $reply = '';

    while (($line = fgets($fp, 1024)) !== false) {
        $reply .= $line;
        // "250-" means more lines follow; "250 " is the last one.
        if (strlen($line) < 4 || $line[3] !== '-') {
            break;
        }
    }

    $reply = trim($reply);
    $log[] = '< ' . $reply;

    if ($reply === '') {
        $meta = stream_get_meta_data($fp);
        throw new RuntimeException(
            !empty($meta['timed_out'])
                ? "timed out waiting for $expect"
                : "connection closed waiting for $expect"
        );
    }

    if ((int) substr($reply, 0, 3) !== $expect) {
        throw new RuntimeException("expected $expect, got: " . substr($reply, 0, 200));
    }

    return $reply;
}
