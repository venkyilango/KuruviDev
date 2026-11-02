<?php
/**
 * POST /api/verify_otp.php
 * Headers: X-Api-Key
 * Body:    {"email": "user@example.com", "code": "123456"}
 *
 * On success returns a short-lived signed proof the app presents when it
 * creates the Firebase account.
 */

require __DIR__ . '/config.php';

$data  = require_post_with_key();
$email = clean_email($data['email'] ?? null);
$code  = preg_replace('/\D/', '', (string) ($data['code'] ?? ''));

if (strlen($code) !== OTP_LENGTH) {
    respond(400, ['ok' => false, 'error' => 'invalid_code_format']);
}

$rec = read_record($email);

if (!$rec) {
    respond(410, ['ok' => false, 'error' => 'expired']);
}

if (time() > (int) $rec['expires_at']) {
    delete_record($email);
    respond(410, ['ok' => false, 'error' => 'expired']);
}

if ((int) $rec['attempts'] >= OTP_MAX_ATTEMPTS) {
    delete_record($email);
    respond(429, ['ok' => false, 'error' => 'too_many_attempts']);
}

// Constant-time compare against the stored hash.
if (!hash_equals($rec['hash'], otp_hash($code, $email))) {
    $rec['attempts'] = (int) $rec['attempts'] + 1;
    write_record($email, $rec);

    respond(401, [
        'ok'        => false,
        'error'     => 'incorrect',
        'remaining' => max(0, OTP_MAX_ATTEMPTS - $rec['attempts']),
    ]);
}

// Correct — burn the code so it can't be replayed.
delete_record($email);

respond(200, [
    'ok'    => true,
    'proof' => issue_proof($email),
]);
