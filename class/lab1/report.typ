#import "../lib/bk.typ/template.typ": *
#show: doc.with(
	department: [Computer Science Department],
  course: [Distributed Systems],
)
#cover(
	[Distributed Systems Lab 1:\ Kubenetes and Kafka],
	instructor: [],
	version: "v1.0",
	department: [Department of Computer
	Science],
	date: datetime.today()
)
#pagebreak()
#set heading(numbering: "I.1.")

= Introduction
In recent years, ...

== Preliminaries
To start, ...


= Hardware and our setup before the thingy thingy
== Le Cong Minh Khang
  write about stupi dum dum ubuntu 24lts whatever
== Le Nguyen Gia Bao
  write about how hes running on his daily driver fedora
== Lê Anh Quân
  write about ...
= Methodology
== lab notes
we follow the fucking lab notes to the letter as best we can. Specifically, the flow is:
 1. Set up k8s on each machine
 2. Connect each machine (as node) to the same k8s cluster
 3. Apply the system spec to the k8s cluster
 4. Each machine
   1. Machine A runs consumer
   2. Machine B runs producer
TODO: diagram
== Ip naming thingy
we doin tailscale cause we already doin that so like its chill bruh we are gonna skip over naming hosts and ips and worker even though khang did rename the ubuntu to worker for no reason
= Implementation
Hell
talk bout the kafka yaml
talk bout the consumer python (client.py) and producer python (server.py)
== Ip naming thingy / name system
we doin tailscale cause we already doin that so like its chill bruh we are gonna skip over naming hosts and ips and worker even though khang did rename the ubuntu to worker for no reason

= Result

tbd

= Related works
shit on the mandetory "production" way this lab forces us to do like the fuck (contrast this against the convenient, high-level CLIs like minikube @minikube and k3s @k3s). This "production" way is involved, but lends itself to much expressiveness so that we cater our system to our needs.
glaze the fuck out of elixir @distex
#bibliography("works.yml")
