ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
hwclock --systohc

echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
locale-gen

echo 'LANG=en_US.UTF-8' > /etc/locale.conf

echo 'What is my hostname: '
read HOSTNAME
echo $HOSTNAME > /etc/hostname

echo 'What domain am I on: '
read DOMAINNAME

echo "Do you have a static IP address?"
echo '`yes` means yes, all else uses 127.0.1.1: '
STATICADDR='127.0.0.1'
read RESPONSE
[[ -z "$RESPONSE" ]] && RESPONSE=no
if [ 'yes' == $RESPONSE ]
then
  echo 'Which IP address would you like to use: '
  read STATICADDR
fi

echo "127.0.0.1	localhost" > /etc/hosts
echo "::1	localhost" >> /etc/hosts
echo "$STATICADDR	$HOSTNAME.$DOMAINNAME	$HOSTNAME" >> /etc/hosts

echo \n---\nNow time to set your root password: \n
passwd

refind-install --usedefault $ESP
