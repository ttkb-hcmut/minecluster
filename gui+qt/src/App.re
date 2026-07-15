open Lablqml

let main = () => {
	let rec ctrl = () => ctrl'(Controller.create_controller())#handler
	and ctrl' = it =>
	{ as _; inherit Controller.controller(it);
		pub onMouseClicked = msg => Printf.printf("Reason says: '%s'\n%!", msg) };
	(ctrl())->set_context_property(~ctx=get_view_exn(~name="rootContext"), ~name="controller");
	print_endline("startup init at Reason side")
}

let () =
	run_with_QQmlApplicationEngine(Sys.argv, main, "qrc:///Root.qml")
