#!/system/bin/sh
# PS5 / konsol icin telefon uzerinden WARP yonlendirmesi
# Kullanim (root gerekli):
#   sh kur.sh start    -> ayarlari goster, arka planda calistir
#   sh kur.sh ayarlar  -> sadece PS5 ayarlarini goster
#   sh kur.sh status   -> durum ve son loglar
#   sh kur.sh stop     -> durdur
#   sh kur.sh auto     -> telefon acilinca otomatik baslasin (Magisk gerekir)

PATH=/system/bin:/system/xbin:/sbin:$PATH
DIR=/data/local/tmp/ps5gw
LOG=$DIR/log.txt
PIDF=$DIR/pid
LAN=wlan0
PS5_SON_OKTET=60
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

mkdir -p $DIR
log() { echo "$(date '+%H:%M:%S') $1" >> $LOG; }

mask_hesapla() {
  p=$1; out=""; i=0
  while [ $i -lt 4 ]; do
    if [ $p -ge 8 ]; then v=255; p=$((p-8))
    elif [ $p -gt 0 ]; then v=$((256 - (1 << (8-p)))); p=0
    else v=0; fi
    if [ $i -eq 0 ]; then out=$v; else out="$out.$v"; fi
    i=$((i+1))
  done
  echo $out
}

lan_bilgi() {
  satir=$(ip -o -4 addr show $LAN 2>/dev/null | head -1)
  TEL_IP=$(echo "$satir" | sed -n 's/.*inet \([0-9.]*\)\/.*/\1/p')
  PREFIX=$(echo "$satir" | sed -n 's/.*inet [0-9.]*\/\([0-9]*\).*/\1/p')
  [ -z "$TEL_IP" ] && return 1
  AG=${TEL_IP%.*}
  NET="$AG.0/$PREFIX"
  PS5_IP="$AG.$PS5_SON_OKTET"
  [ "$PS5_IP" = "$TEL_IP" ] && PS5_IP="$AG.61"
  MASK=$(mask_hesapla $PREFIX)
  return 0
}

ayarlar_goster() {
  lan_bilgi || { echo "wlan0 uzerinde IP yok. Wi-Fi'ye bagli misin?"; return 1; }
  echo "=============================="
  echo " PS5 AYARLARI (bu telefonda)"
  echo "=============================="
  echo " IP Adresi Ayarlari : Manuel"
  echo " IPv4 Adresi        : $PS5_IP"
  echo " Alt Ag Maskesi     : $MASK"
  echo " Varsayilan Gecit   : $TEL_IP"
  echo " Birincil DNS       : 1.1.1.1"
  echo " Ikincil DNS        : 8.8.8.8"
  echo " Proxy              : Kullanma"
  echo " MTU                : Otomatik"
  echo "=============================="
  echo " Telefonun IP'si degisirse: sh kur.sh ayarlar"
}

ekle() {
  t=$1; shift
  iptables -t $t -C "$@" 2>/dev/null || iptables -t $t -I "$@"
}

uygula() {
  T=$(ip -o link show 2>/dev/null | grep -o 'tun[0-9]*' | head -1)
  if [ -z "$T" ]; then
    [ "$DURUM" != "yok" ] && log "tunel yok, bekleniyor"
    DURUM=yok; return 1
  fi
  [ "$DURUM" != "var" ] && log "tunel aktif: $T"
  DURUM=var
  lan_bilgi
  TT=$(ip route show table all dev $T 2>/dev/null | grep -o 'table [^ ]*' | head -1 | awk '{print $2}')
  [ -z "$TT" ] && TT=$T
  echo 1 > /proc/sys/net/ipv4/ip_forward
  for i in all $LAN $T; do echo 0 > /proc/sys/net/ipv4/conf/$i/rp_filter 2>/dev/null; done
  ekle nat POSTROUTING -o $T -j MASQUERADE
  ekle filter FORWARD -i $LAN -o $T -j ACCEPT
  ekle filter FORWARD -i $T -o $LAN -m state --state RELATED,ESTABLISHED -j ACCEPT
  ekle mangle FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
  ip rule | grep -q "to $NET lookup $LAN" || ip rule add pref 4999 to $NET lookup $LAN
  if ! ip rule | grep -q "iif $LAN lookup $TT"; then
    ip rule del pref 5000 2>/dev/null
    ip rule add pref 5000 iif $LAN lookup $TT
    log "kural 5000 guncellendi: $T tablo $TT"
  fi
}

dongu() {
  echo $$ > $PIDF
  until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 5; done
  sleep 15
  DURUM=""
  while true; do uygula; sleep 10; done
}

durdur() {
  [ -f $PIDF ] && kill $(cat $PIDF) 2>/dev/null
  for p in /proc/[0-9]*; do
    tr '\0' ' ' < $p/cmdline 2>/dev/null | grep -q 'kur.sh dongu' && kill ${p#/proc/} 2>/dev/null
  done
  rm -f $PIDF
}

baslat() {
  durdur
  ayarlar_goster || exit 1
  setsid sh "$SELF" dongu </dev/null >/dev/null 2>&1 &
  cp "$SELF" $DIR/kur.sh
  echo ""
  echo "Calisiyor. Durum icin: sh kur.sh status"
}

durum() {
  echo "--- Son loglar"; tail -5 $LOG 2>/dev/null
  echo "--- Kurallar"; ip rule | grep -E '^(4999|5000):'
  echo "--- Sayaclar"; iptables -L FORWARD -n -v | grep -E 'wlan0|tun'
  echo ""; ayarlar_goster
}

oto() {
  cp "$SELF" $DIR/kur.sh
  printf '#!/system/bin/sh\nsetsid sh /data/local/tmp/ps5gw/kur.sh dongu </dev/null >/dev/null 2>&1 &\n' > /data/adb/service.d/ps5gw.sh
  chmod 755 /data/adb/service.d/ps5gw.sh
  echo "Otomatik baslatma kuruldu. Telefon acilinca calisir (Magisk gerekir)."
}

case "$1" in
  start)   [ "$(id -u)" = "0" ] || { echo "Once root al: su"; exit 1; }; baslat ;;
  dongu)   dongu ;;
  ayarlar) ayarlar_goster ;;
  status)  durum ;;
  stop)    durdur; echo "Durduruldu" ;;
  auto)    oto ;;
  *)       echo "Kullanim: sh kur.sh start | ayarlar | status | stop | auto" ;;
esac
