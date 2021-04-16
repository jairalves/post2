provider "vsphere" {
  user           = "${var.vsphere_user}"
  password       = "${var.vsphere_password}"
  vsphere_server = "${var.vsphere_server}"

  # if you have a self-signed cert
  allow_unverified_ssl = true
}
data "vsphere_datacenter" "dc" {
  name = "lab-vmware"
}
data "vsphere_datastore" "datastore" {
  name          = "AMBIENTE_LAB"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}
data "vsphere_compute_cluster" "cluster" {
    name          = "lab-cluster"
    datacenter_id = "${data.vsphere_datacenter.dc.id}"
}
data "vsphere_network" "network" {
  name          = "DMZ_AMB_LABORATORIO"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}
data "vsphere_virtual_machine" "template" {
  name          = "Win2016_Update"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "vm" {

    count            = "1"
    name             = "Windows-Teste0${count.index + 1}"
    folder           = "Teste-TF"
    resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
    datastore_id     = "${data.vsphere_datastore.datastore.id}"
    firmware         = "${data.vsphere_virtual_machine.template.firmware}"
    num_cpus = 2
    memory   = 6144
    guest_id = "${data.vsphere_virtual_machine.template.guest_id}"
    network_interface {
        network_id   = "${data.vsphere_network.network.id}"
        adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"       
    }
    disk {
        label            = "disk0"
        size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
        eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
        thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
    }
    scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

    clone {
        template_uuid = "${data.vsphere_virtual_machine.template.id}"

        customize {
            windows_options {
                computer_name  = "Windows-Teste0${1 + count.index}"
                admin_password = "P@ssw0rd"
                join_domain = "lab.com"
	              domain_admin_user = "administrator"
	              domain_admin_password = "P@ssw0rd"
            }
        
            network_interface {
            ipv4_address = "10.221.150.10${1 + count.index}"
            ipv4_netmask = 24
            dns_server_list = ["10.221.150.8"]
            }
            ipv4_gateway = "10.221.150.254"
        }    
    }
}

