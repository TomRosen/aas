namespace AASDialog {

    public void error (string error_message, Gtk.Window parent) {
        string report_url = "http://github.com/tomrosen/aas/issues";
        Gtk.Dialog dialog = new Gtk.Dialog.with_buttons (
            _("Error"),
            parent,
            Gtk.DialogFlags.MODAL |
            Gtk.DialogFlags.DESTROY_WITH_PARENT,
            _("Report Problem"), 1,
            _("Close"), 2, null
        ) {
            resizable = false
        };
        
        dialog.response.connect ((response_id)=>{
            if (response_id == 1) {
                Gtk.show_uri_on_window (parent,report_url,Gdk.CURRENT_TIME);
            } else if (response_id == 2) {
                dialog.destroy ();
            }
        });
        
        Gtk.Label error_label = new Gtk.Label (_("Error: ") + error_message) {
            margin = 10,
        };
        
        error_label.set_line_wrap (true);
        error_label.set_max_width_chars (50);
        
        dialog.get_content_area ().add (error_label);
        
        dialog.show_all ();
        dialog.present ();
    }
    
    public void message (string info_message, Gtk.Window parent) {
        GLib.Settings settings = new GLib.Settings ("com.github.tomrosen.aas");
        Gtk.Dialog dialog = new Gtk.Dialog.with_buttons (
            _("Message"),
            parent,
            Gtk.DialogFlags.MODAL |
            Gtk.DialogFlags.DESTROY_WITH_PARENT,
            null
        ) {
            resizable = false
        };
        
        Gtk.Label info_label = new Gtk.Label (info_message) {
            margin = 10,
            halign = Gtk.Align.START
        };
        
        info_label.set_line_wrap (true);
        info_label.set_max_width_chars (50);
        
        Gtk.CheckButton check_button = new Gtk.CheckButton.with_label (_("Don't show again"));
        Gtk.Button button = new Gtk.Button.with_label (_("Ok"));
        
        button.clicked.connect (()=>{
            settings.set_boolean ("show-info-apply",!check_button.get_active ());
            dialog.destroy ();
        });
        
        dialog.get_content_area ().add (info_label);
        dialog.get_action_area ().add (check_button);
        dialog.get_action_area ().add (button);
        
        dialog.show_all ();
        dialog.present ();
    }
    
    
}
