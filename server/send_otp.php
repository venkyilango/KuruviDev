<?php
/**
 * POST /api/send_otp.php
 * Headers: X-Api-Key
 * Body:    {"email": "user@example.com"}
 *
 * Generates a one-time code, stores only its hash, and emails the code.
 */

require __DIR__ . '/config.php';
require __DIR__ . '/mailer.php';

$data  = require_post_with_key();
$email = clean_email($data['email'] ?? null);

gc_store();

// --- Flood guards -----------------------------------------------------------

if (!ip_budget_ok()) {
    respond(429, ['ok' => false, 'error' => 'too_many_requests']);
}

$existing = read_record($email);
if ($existing && isset($existing['sent_at'])) {
    $wait = RESEND_COOLDOWN_SEC - (time() - (int) $existing['sent_at']);
    if ($wait > 0) {
        respond(429, [
            'ok'           => false,
            'error'        => 'cooldown',
            'retry_after'  => $wait,
        ]);
    }
}

// --- Generate ---------------------------------------------------------------

$max  = (10 ** OTP_LENGTH) - 1;
$code = str_pad((string) random_int(0, $max), OTP_LENGTH, '0', STR_PAD_LEFT);

write_record($email, [
    'hash'       => otp_hash($code, $email),
    'expires_at' => time() + (OTP_TTL_MINUTES * 60),
    'attempts'   => 0,
    'sent_at'    => time(),
]);

// --- Send -------------------------------------------------------------------

$mins = OTP_TTL_MINUTES;
$safe = htmlspecialchars($code, ENT_QUOTES, 'UTF-8');

$html = <<<HTML
<!doctype html>
<html><body style="margin:0;background:#f4f6f8;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif">
  <div style="max-width:480px;margin:0 auto;padding:32px 24px">
    <div style="background:#fff;border-radius:12px;padding:32px;border:1px solid #e3e8ee">
      <p style="margin:0 0 4px;font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:#3E729F;font-weight:700">Kuruvi</p>
      <h1 style="margin:0 0 16px;font-size:20px;color:#1b1f24">Verify your email</h1>
      <p style="margin:0 0 24px;font-size:15px;line-height:1.6;color:#5b6672">
        Use this code to finish creating your Kuruvi account.
      </p>
      <div style="background:#eef4f9;border-radius:10px;padding:20px;text-align:center;margin:0 0 24px">
        <span style="font-size:34px;font-weight:700;letter-spacing:9px;color:#3E729F;font-family:monospace">$safe</span>
      </div>
      <p style="margin:0 0 8px;font-size:14px;color:#5b6672">
        This code expires in <strong>$mins minutes</strong>.
      </p>
      <p style="margin:0;font-size:13px;color:#8a95a1">
        If you didn't request this, you can safely ignore this email — no account will be created.
      </p>
    </div>
  </div>
</body></html>
HTML;

[$sent, $detail] = send_email($email, MAIL_SUBJECT, $html);

if (!$sent) {
    delete_record($email); // don't leave a code the user can never receive

    // `detail` is only echoed back when DEBUG_SEND is on, so provider errors
    // stay off the wire in normal operation.
    respond(502, DEBUG_SEND
        ? ['ok' => false, 'error' => 'send_failed', 'detail' => $detail]
        : ['ok' => false, 'error' => 'send_failed']);
}

respond(200, [
    'ok'         => true,
    'expires_in' => OTP_TTL_MINUTES * 60,
]);
