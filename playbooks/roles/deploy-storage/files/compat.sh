#!/bin/bash

echo "Reading Swarm secrets"
for f in ceph.mon.keyring ceph.client.admin.keyring; do
    [ -e /run/secrets/$f ] && cp /run/secrets/$f /etc/ceph/$f
done
for d in osd mds rbd rgw; do
    if [ -e /run/secrets/ceph.bootstrap-$d.keyring ]; then
      mkdir -p /var/lib/ceph/bootstrap-$d
      cp /run/secrets/ceph.bootstrap-$d.keyring /var/lib/ceph/bootstrap-$d/ceph.keyring
    fi
done

if [ "$1" == "mon" ]; then
  base="/var/lib/ceph/mon/ceph-`hostname`"
  if [ ! -e "$base/keyring" -a -e /run/secrets/monmap ]; then
    echo "Bootstrapping new mon from Swarm secrets"
    mkdir -p $base && chown ceph:ceph $base
    ceph-mon --setuser ceph --setgroup ceph --cluster ceph --mkfs -i `hostname` --monmap /run/secrets/monmap --keyring /etc/ceph/ceph.mon.keyring --mon-data $base
  fi
fi

exec /opt/ceph-container/bin/entrypoint.sh "$@"