resource "google_compute_network" "production" {
	name = "${var.network_name}"
	ipv4_range = "${var.iprange}"
}

#Provision the static IPs for nginx
resource "google_compute_address" "ngnxaddress" {
	count = "3"
	name = "ngx${count.index}address"
}

#Provision the static IPs for nat
resource "google_compute_address" "nataddress" {
	count = "1"
	name = "nat${count.index}address"
}

#Provision the static IPs for bastionbox
resource "google_compute_address" "bastionaddress" {
	count = "1"
	name = "bast${count.index}address"
}

#Create the firewalls for the layered net ssh access
resource "google_compute_firewall" "ssh" {
	name = "sshwall"
	network = "${google_compute_network.production.name}"
	
    allow {
        protocol = "tcp"
        ports = ["22"]
    }	

	source_ranges = ["${var.external_net}"]
}

#Create the firewalls for the layered net
resource "google_compute_firewall" "internal" {
	name = "intwall"
	network = "${google_compute_network.production.name}"
	
    allow {
        protocol = "tcp"
        ports = ["1-65535"]
    }	

    allow {
        protocol = "udp"
        ports = ["1-65535"]
    }
	source_tags = ["internal"]
	source_ranges = ["${var.internal_net}"]
}

resource "google_compute_firewall" "webwall" {
    name = "webwall"
    network = "${google_compute_network.production.name}"

    allow {
        protocol = "tcp"
        ports = ["80", "443"]
    }

    source_ranges = ["${var.external_net}"]
    target_tags = ["web"]
}

#Create the route for nat and no ips
resource "google_compute_route" "no_ips" {
	name = "noiproute"
	dest_range = "${var.external_net}"
	network = "${google_compute_network.production.name}"
	next_hop_instance_zone = "${var.region_name}-a"
	next_hop_instance = "natgatew"
	priority = 500
	tags = ["no-ip"]
	depends_on = ["google_compute_instance.natgateway"]
} 

#Create the nat gateway instance
resource "google_compute_instance" "natgateway" {
	count = "1"
	name = "natgatew"
	machine_type = "${var.layer1type.gce}"
	zone = "${lookup(var.azones, concat("zon", count.index))}"
	tags = ["nat","internal","ssh"]
	can_ip_forward = "true"
	
	disk {
		image = "centos-6-v20141205"
		type = "pd-ssd"
	}	
	
	network_interface {
		network = "${google_compute_network.production.name}"
		access_config { 
		nat_ip = "${element(google_compute_address.nataddress.*.address,count.index)}"
		}
	}
	metadata {	
		host_group = "natgate"
		sshKeys = "${var.sshkeys.opskey}"
	}

	provisioner "remote-exec" {
		connection {
			user = "${var.bastion_user}"
			key_file = "${var.bastion_key}"
		}
		scripts = ["scripts/setnat.sh","scripts/setfire.sh"]
	}	

}


resource "google_compute_subnetwork" "custom" {
  name          = "test-subnetwork"
  ip_cidr_range = "10.2.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.custom.id
  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "192.168.1.0/24"
  }

  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "192.168.64.0/22"
  }
}

resource "google_compute_network" "custom" {
  name                    = "test-network"
  auto_create_subnetworks = false
}

resource "google_container_cluster" "my_vpc_native_cluster" {
  name               = "my-vpc-native-cluster"
  location           = "us-central1"
  initial_node_count = 1

  network    = google_compute_network.custom.id
  subnetwork = google_compute_subnetwork.custom.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "services-range"
    services_secondary_range_name = google_compute_subnetwork.custom.secondary_ip_range.1.range_name
  }
}