# Onay Protokolü (approval-protocol.md)

1. Model tehlikeli / yan etkili eylemleri doğrudan yürütemez.
2. Eylem `propose_action` ile teklif edilir.
3. UI tarafında tek kullanımlık `ApprovalToken` üretilir (Geçerlilik: 120 saniye, tek seferlik kullanım).
4. Kullanıcı ekrandan "Onayla" butonuna basarak veya sesli olarak "Evet, onayla" dediğinde token geçerli kılınır ve `execute_approved_action(approval_token)` çağrılır.
5. Model asla kendiliğinden token üretemez. Geçersiz veya zaman aşımına uğramış tokenlar reddedilir.
