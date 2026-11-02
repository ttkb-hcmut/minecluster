#import "../lib/bk.typ/template.typ": *
#show: doc.with(
	department: [Computer Science Department],
  course: [Distributed Systems],
)
#cover(
	[Distributed Systems Lab 1:\ Kubernetes and Kafka],
	instructor: [Đỗ Quang Hào],
	version: "v1.0",
	department: [Department of Computer
	Science],
	date: datetime.today()
)
#pagebreak()
#set heading(numbering: "I.1.")


// uhh we probably dont need intro and prelim for such a simple report
// = Introduction
// In recent years, ...

// == Preliminaries
// To start, ...


= Starting point
This section outlines the particular setups we did the lab assignment on:
- Le Cong Minh Khang: Ubuntu 24.04.1 lts running on a windows 10 laptop via WSL
- Le Nguyen Gia Bao: TODO(Bao):write about how hes running on his daily driver fedora
- Lê Anh Quân: write about ...
= Methodology
== lab notes
we follow lab notes available to us on the lms as best we can with a few tweaks for our specific circumstances. Specifically:
+ Disable `SELINUX` and firewalls
+ Setting up hostnames for the machines is handled via Tailscale, as we have already have it set up before hand. It allows you to refer to Tailscale assigned names similarly across the web
+ Configure and install kubernetes and the container runtime 
+ Connect each machine (as node) to the same k8s cluster
+ Apply the system spec to the k8s cluster
+ Each machine
 - Machine A runs consumer
 - Machine B runs producer
TODO: diagram
= Implementation
Our kafka.yaml is largely based on the provided file on the LMS, with a few minor tweaks (rewriting some lines to be single lined?) and a chunk of the code deleted(?) TODO(bao):explain

To test the connections, we use 2 python files with `confluent_kafka` imported `server.py` and `client.py`.
- `server.py` is a simple `Producer` sending test messages.
- `client.py` is a simple `Consumer` that periodically polls for and prints any messages it finds to the terminal.
If everything is setup correctly, the `Consumer` should repeatedly print out `no msg` until the `Producer` sends messages for it to print

= Result

TODO: images (idk how to put a video here)

= Related works
TODO(Bao): complain about the mandetory "production" way this lab wants us to do (contrast this against the convenient, high-level CLIs like minikube @minikube and k3s @k3s). This "production" way is involved, but lends itself to much expressiveness so that we cater our system to our needs.
TODO(Khang): glaze the fuck out of elixir and the Erlang's communication @distex
#bibliography("works.yml")
