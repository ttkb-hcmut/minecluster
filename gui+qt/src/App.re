open Lablqml

let main = () => {
	let ctrl' = Controller.create_controller();
	let ctrl =
	{ as _; inherit Controller.controller(ctrl');
		pub onMouseClicked = msg => Printf.printf("Reason says: '%s'\n%!", msg) };
	ctrl#handler->set_context_property(~ctx=get_view_exn(~name="rootContext"), ~name="controller");
	print_endline("startup init at Reason side")
}

let () =
	run_with_QQmlApplicationEngine(Sys.argv, main, "qrc:///Root.qml")
