# ps5-wifi-gateway

Root'lu Android telefonu PS5 ve diğer konsollar için ağ geçidi yapar. Trafik Cloudflare WARP tüneli üzerinden çıkar.

## Gereksinimler

- Root (Magisk önerilir)
- Termux
- Cloudflare WARP, açık ve bağlı
- Telefon ve konsol aynı Wi-Fi ağında

## Kurulum

Termux'u aç ve aşağıdaki komutları **birer birer**, sırayla yaz. Her birinden sonra Enter'a bas ve bitmesini bekle.

**1. Curl'ü kur**
pkg install curl -y
**2. Kurulum dosyasını indir**
curl -fsSL https://raw.githubusercontent.com/osmanilgin91k/ps5-wifi-gateway/main/kur.sh -o ~/kur.sh
**3. Ayarları göster ve sistemi başlat**
su -c "sh /data/data/com.termux/files/home/kur.sh start"
Ekranda PS5'e yazacağın IP, maske, ağ geçidi ve DNS değerleri çıkar.

## Diğer komutlar

- `su -c "sh /data/data/com.termux/files/home/kur.sh ayarlar"` : PS5 ayarlarını tekrar göster
- `su -c "sh /data/data/com.termux/files/home/kur.sh status"` : Durum ve loglar
- `su -c "sh /data/data/com.termux/files/home/kur.sh stop"` : Durdur
- `su -c "sh /data/data/com.termux/files/home/kur.sh auto"` : Telefon açılınca otomatik başlat (Magisk gerekir)

## Uyarı

Scripti çalıştırmadan önce içeriğini oku. Root yetkisiyle çalışır.

## Destek

Sorun yaşarsanız Instagram: (osmanilgin90) veya direk e posta: (support@xosmanx07.qzz.io) üzerinden mesaj iletebilirsiniz.
