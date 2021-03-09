#!/bin/bash -xe
#
# This user-data script has been written in a way to be re-usable by
# any ansible playbook you wish to run at the provisioning stage
# where you may not have the ability to remotely execute Ansible.
# E.g. behind firewalls, where port 22 is denied.

# Bootstraps enough config to allow Ansible to pull down the
# playbook and run with extra variables pumped in from
# terraform's template vars

# Instances with less than 1GB of memory struggle when Ansible tries to install packages.
# Attach a temporary swapfile to deal with that.

# Loading kernel modules has the potential to fail due to possible kernel updates
# with `yum update` not playing nicely with dkms. Just reboot the box after updates
# and continue the installation.

exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

BOOT_TOUCHFILE=/var/tmp/first_boot

# Update the system then reboot
if ! [[ -e $BOOT_TOUCHFILE ]]; then
  touch $BOOT_TOUCHFILE

  for i in {1..3}; do
    echo "Attempt: ---- " $i
    yum -y update && break || sleep 60
  done

  # Trick cloud-init into thinking the next boot will be its first
  rm /var/lib/cloud/instances/*/sem/config_scripts_user

  echo "Rebooting after updates"
  reboot
fi

TOTAL_MEM_MB=$(free -m --total | grep ^Total | awk '{print $2}')

# Give the instance enough temporary swap space for yum not to starve the available memory
# and crash the installation
if [[ $TOTAL_MEM_MB -lt 1000 ]]; then
  dd if=/dev/zero of=/swapfile bs=128M count=4
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
fi

amazon-linux-extras install -y ansible2
yum install -y git

cat > ~/.ansible.cfg << EOF
[defaults]
inventory = ~/.ansible-hosts
# interpreter_python = /usr/bin/python2
ansible_managed =
                  # --- Ansible managed ---
                  # {file}
                  # modified date - %Y-%m-%d %H:%M:%S
                  # by {uid} on {host}
                  #
EOF

echo "localhost ansible_connection=local" > ~/.ansible-hosts

git clone -b '${tf_ansible_playbook_release}' --single-branch ${tf_ansible_playbook_url} ${tf_ansible_playbook_directory}

ansible-galaxy install -r ${tf_ansible_playbook_directory}/requirements.yml

ansible-galaxy collection install -r ${tf_ansible_playbook_directory}/requirements.yml

ansible-playbook ${tf_ansible_playbook_directory}/site.yml --extra-vars '${tf_wireguard_playbook_config}'
RC=$?

if [[ $RC -eq 0 ]]; then
  echo "Success: Installation complete. Goodbye!"
else
  echo "Error: Ansible playbook exited with status code ($RC). Installation failed!"
fi

# Clean up the swapfile if it exists.
if [[ -e "/swapfile" ]]; then
  swapoff /swapfile
  rm /swapfile
fi

rm $BOOT_TOUCHFILE

exit $RC
