resource "google_compute_instance" "bastion" {
	count = "1"
	name = "bast${count.index}"
	machine_type = "${var.layer2type.gce}"
	zone = "${lookup(var.azones, concat("zon", count.index))}"
	tags = ["internal","ssh","bastion"]
	
	disk {
		image = "centos-6-v20141205"
	}
	
	network_intaerface {
		network = "${google_compute_network.production.name}"
		access_config { 
		nat_ip = "${element(google_compute_address.bastionaddress.*.address,count.index)}"
		}
	}
			
	metadata {	
		host_group = "bastionnodes"
		sshKeys = "${var.sshkeys.opskey}"
	}
	provisioner "remote-exec" {
		connection {
			user = "${var.bastion_user}"
			key_file = "${var.bastion_key}"
		}
		script = "scripts/setfire.sh"
	}
}

#Create the persistent disks for database storage
resource "google_compute_disk" "data" {
	count = "3"
	name = "data${count.index}"
	type = "pd-standard"
	zone = "${lookup(var.azones, concat("zon", count.index))}"
	size = "1000"
}

#Setup the frontend loadbalancers
resource "google_compute_instance" "loadbalancers" {
	count = "3"
	name = "lb${count.index}"
	machine_type = "${var.layer1type.gce}"
	zone = "${lookup(var.azones, concat("zon", count.index))}"
	tags = ["web","layer1","ssh"]
	
	disk {
		image = "centos-6-v20141205"
	}
	
	network_interface {
		network = "${google_compute_network.production.name}"
		access_config { 
		nat_ip = "${element(google_compute_address.ngnxaddress.*.address,count.index)}"
		}
	}
	
	metadata {	
		host_group = "loadbalancers"
		sshKeys = "${var.sshkeys.opskey}"
	}

	provisioner "remote-exec" {
		connection {
			user = "${var.bastion_user}"
			key_file = "${var.key_path}"
		}
		script = "scripts/setfire.sh"
	}
}

#Create the application nodes
resource "google_compute_instance" "appnodes" {
	count = "3"
	name = "app${count.index}"
	machine_type = "${var.layer2type.gce}"
	zone = "${element(google_compute_instance.loadbalancers.*.zone,count.index)}"
	tags = ["app", "internal", "layer2","ssh","no-ip"]
	depends_on = ["google_compute_route.no_ips"]

	
	disk {
		image = "centos-6-v20141205"
		type = "pd-ssd"
	}
	
	network_interface {
		network = "${google_compute_network.production.name}"
	}
			
	metadata {	
		host_group = "appnodes"
		sshKeys = "${var.sshkeys.opskey}"
	}

}

#Create the DB instances and attach the disks
resource "google_compute_instance" "dbsnodes" {
	count = "3"
	name = "dbs${count.index}"
	machine_type = "${var.layer3type.gce}"
	zone = "${element(google_compute_instance.loadbalancers.*.zone,count.index)}"
	tags = ["dbs", "internal", "layer3","ssh","no-ip"]
	depends_on = ["google_compute_route.no_ips"]
		
	disk {
		image = "centos-6-v20141205"
		type = "pd-ssd"
	}
	
	disk {
		disk = "${element(google_compute_disk.data.*.name,count.index)}"
	}
	
	network_interface {
		network = "${google_compute_network.production.name}"
	}
			
	metadata {	
		host_group = "dbsrvs"
		sshKeys = "${var.sshkeys.solidkey}"
	}
		
}