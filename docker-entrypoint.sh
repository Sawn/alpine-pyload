#!/bin/sh

MYUSER="pyload"
MYGID="10005"
MYUID="10005"

ConfigureSsmtp () {
  # Customizing sstmp
  if [ -f /etc/ssmtp/ssmtp.conf ];then
    # Configure relay
    if [ -n "${DOCKRELAY}" ]; then
      /bin/sed -i "s|mailhub=mail|mailhub=${DOCKRELAY}|i" /etc/ssmtp/ssmtp.conf
    fi
    # Configure root
    if [ -n "${DOCKMAIL}" ]; then
      /bin/sed -i "s|root=postmaster|root=${DOCKMAIL}|i" /etc/ssmtp/ssmtp.conf
    fi
    # Configure domain
    if [ -n "${DOCKMAILDOMAIN}" ]; then
      /bin/sed -i "s|#rewriteDomain=.*|rewriteDomain=${DOCKMAILDOMAIN}|i" /etc/ssmtp/ssmtp.conf
    fi
  fi
}

ConfigureUser () {
  # Managing user
  if [ -n "${DOCKUID}" ]; then
    MYUID="${DOCKUID}"
  fi
  # Managing group
  if [ -n "${DOCKGID}" ]; then
    MYGID="${DOCKGID}"
  fi
  local OLDHOME
  local OLDGID
  local OLDUID
  /bin/grep -q "${MYUSER}" /etc/passwd
  if [ $? -eq 0 ]; then
    OLDUID=$(/usr/bin/id -u "${MYUSER}")
    OLDGID=$(/usr/bin/id -g "${MYUSER}")
    if [ "${DOCKUID}" != "${OLDUID}" ]; then
      OLDHOME=$(/bin/echo "~${MYUSER}")
      /usr/sbin/deluser "${MYUSER}"
      /usr/bin/logger "Deleted user ${MYUSER}"
    fi
    /bin/grep -q "${MYUSER}" /etc/group
    if [ $? -eq 0 ]; then
      local OLDGID=$(/usr/bin/id -g "${MYUSER}")
      if [ "${DOCKGID}" != "${OLDGID}" ]; then
        /usr/sbin/delgroup "${MYUSER}"
        /usr/bin/logger "Deleted group ${MYUSER}"
      fi
    fi
  fi
  /usr/sbin/addgroup -S -g "${MYGID}" "${MYUSER}"
  /usr/sbin/adduser -S -D -H -s /sbin/nologin -G "${MYUSER}" -h "${OLDHOME}" -u "${MYUID}" "${MYUSER}"
  if [ -n "${OLDUID}" ] && [ "${DOCKUID}" != "${OLDUID}" ]; then
    /usr/bin/find / -user "${OLDUID}" -exec /bin/chown ${MYUSER} {} \;
  fi
  if [ -n "${OLDGID}" ] && [ "${DOCKGID}" != "${OLDGID}" ]; then
    /usr/bin/find / -group "${OLDGID}" -exec /bin/chgrp ${MYUSER} {} \;
  fi
}

ConfigureUser
ConfigureSsmtp

if [ "$1" = 'pyload' ]; then
    if [ -d /config ]; then
      /bin/chown -R "${MYUSER}":"${MYUSER}" /config
      /bin/chmod 0775 /config
    fi
    if [ -e /config/pyload.pid ]; then
      /bin/rm /config/pyload.pid
    fi
    for J in package_finished download_finished; do 
      if [ ! -d /config/scripts/${J} ]; then
        /bin/mkdir -p /config/scripts/${J}
        /bin/chown -R "${MYUSER}":"${MYUSER}" /config/scripts/${J}
        /bin/chmod 0775 /config/scripts/${J}
      fi
    done
    if [ ! -f /config/scripts/package_finished/mail-notification.sh ]; then
      cat << EOF2 > /config/scripts/package_finished/mail-notification.sh
#!/bin/sh
/usr/bin/mail -s "Pyload: Package Finished" root <<EOF
\${1} was finished at \$(date +"%H:%M") on \$(date +"%d.%m.%y"). ...forwarding it now to the extraction queue.
EOF
EOF2
      /bin/chown -R "${MYUSER}":"${MYUSER}" /config/scripts/package_finished/mail-notification.sh
      /bin/chmod 0775 /config/scripts/package_finished/mail-notification.sh
    fi
    if [ ! -f /config/scripts/download_finished/mail-notification.sh ]; then
      cat << EOF2 > /config/scripts/download_finished/mail-notification.sh
#!/bin/sh
/usr/bin/mail -s "Pyload: Download Finished" root <<EOF
\${1} was finished at \$(date +"%H:%M") on \$(date +"%d.%m.%y"). ...forwarding it now to the extraction queue.
EOF
EOF2
      /bin/chown -R "${MYUSER}":"${MYUSER}" /config/scripts/download_finished/mail-notification.sh
      /bin/chmod 0775 /config/scripts/download_finished/mail-notification.sh
    fi
    exec /sbin/su-exec "${MYUSER}" /usr/bin/python /opt/pyload/pyLoad.py --configdir=/config 
fi

exec "$@"
