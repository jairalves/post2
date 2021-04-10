provider "vsphere" {
  user           = "${var.vsphere_user}"
  password       = "${var.vsphere_password}"
  vsphere_server = "${var.vsphere_server}"

  # if you have a self-signed cert
  allow_unverified_ssl = true
}
data "vsphere_datacenter" "dc" {
  name = "Equinix"
}
data "vsphere_datastore" "datastore" {
  name          = "lun_VDI_HB_92"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}
data "vsphere_compute_cluster" "cluster" {
    name          = "SPEQXCLUSTER"
    datacenter_id = "${data.vsphere_datacenter.dc.id}"
}
data "vsphere_network" "network" {
  name          = "PEP_CATHO_VDI"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}
data "vsphere_virtual_machine" "template" {
  name          = "TEMPLATE_VDI_CATHO_01"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "vm" {

    count            = "1"
    name             = "SPEQXVDICATHO${count.index + 1}"
    folder           = "VDI-CATHO"
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
                computer_name  = "SPEQXVDICATH${1 + count.index}"
                join_domain = "catho.local"
	              domain_admin_user = "jalvesadm"
	              domain_admin_password = "Mutant@2020"
            }
        

            network_interface {
            ipv4_address = "10.126.0.${1 + count.index}"
            ipv4_netmask = 24
            dns_server_list = ["10.125.1.177"]
            }
            ipv4_gateway = "10.126.0.254"
        }    
    }
}

