== System as a service

There is a tight, intimate connection between the GUI and the system. The GUI sends commands #fn[messages, amongst the variants is command message] that are executed by the systems; the system acts as a decoupled interpreter. The connection is a pair of "pipes", specifically, UNIX file sockets #fn[on Windows, file sockets aren't available, so we opt for the conventional port-based TCP sockets, and we make sure to query for free, unique port numbers] local for each application instance.
