(Automatic) host migration for peer-to-peer servers. By itself, host migration is generic.  Godot's MultiplayerSynchronizer #footnote("https://github.com/godotengine/godot-proposals/issues/7912"), Unity's netcode system #footnote("https://docs.unity3d.com/Packages/com.unity.netcode@1.5/manual/host-migration/host-migration-systems.html").  Well-known, host migration is deployed in distributed SaaS servers as a kind of transfer of responsibility. However, host migration in p2p context is interesting, it effectively means a model of "tồn tại theo nhu cầu", but it is challenging that the peers usually don't have the full context of the system à la distributed programming.

#v(2em)

For minecraft, servers have been implementing their own protocols to implement seamless transfer of player clients, these are ad-hoc and requires hacking of minecraft server protocols, they are implemented as a feature of many server packages. "Seamless" is YMMV, usually a loading screen is briefly present #footnote("https://www.reddit.com/r/Minecraft/s/HyUkAaQ5VZ").

Recently, minecraft 1.20.1 introduces transfer packets which, for first time, formalizes the notion of host transfer. As of this writing, only one github project is known to utilize this new feature.

Most importantly, none of the minecraft examples above demonstrated a combination of host transfer with p2p. Indeed, it's not hard to imagine that host migration is a method, client-server has been the model, and that the model can be swapped with another one, here, a distributed p2p system.

#v(2em)

Our host transfer aims to be seamless. This can be seen as seamless backend server transfer #footnote("https://www.reddit.com/r/Minecraft/comments/1uofoa7/no_disconnect_no_loading_screen_just_a_seamless/"). This is packet forwarding. This requires intercepting Minecraft server packets, deep integration with minecraft server communication protocol. Recently, minecraft 1.20.1 introduces transfer packets which, for first time, formalizes packet forwarding. Minecluster's host transfer is a shallow integration, the server program is managed in the fashion that it is started by shell-out running the server program command, it is managed as an external process by the operating system, there's no controlling of its egress or ingress trafficking, only its lifecycle.

// In the literature of virtual machines:
// Host election
// State preservation
// {Graceful|} hand-over
// Chained migrations
// Packet forwarding
//

// #bibliography("works.yml")
