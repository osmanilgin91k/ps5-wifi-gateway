# ps5-wifi-gateway

Root'lu Android telefonu PS5 ve diger konsollar icin ag gecidi yapar. Trafik Cloudflare WARP tuneli uzerinden cikar.

## Kurulum (Termux)

pkg install curl -y
curl -fsSL https://raw.githubusercontent.com/osmanilgin91k/ps5-wifi-gateway/main/kur.sh -o ~/kur.sh
su -c "sh /data/data/com.termux/files/home/kur.sh start"

Ekranda konsola yazilacak IP, maske, ag gecidi ve DNS degerleri cikar.

## Komutlar
- start    : Baslat
- ayarlar  : Konsol ayarlarini goster
- status   : Durum ve loglar
- stop     : Durdur
- auto     : Telefon acilinca otomatik baslat (Magisk)

## Uyari
Scripti calistirmadan once icerigini oku. Root yetkisiyle calisir.
