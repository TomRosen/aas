/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 Tom Rosen <dev@tomrosen.de>
 */

using Gee;

public class AAS : Gtk.Application {
    public bool loading_error {get; construct;}
    public string loading_error_message {get; construct;}
    public HashMap<string,string> parsed_options {get; construct;}
    public Options options {get; construct;}
    public Components components {get; construct;}
    public GLib.Settings settings {get; construct;} 
    
    private HashMap<string,Gtk.ComboBoxText> ui_comboboxes = new HashMap<string,Gtk.ComboBoxText> ();
    private HashMap<string,Gtk.CheckButton> ui_checkbuttons = new HashMap<string,Gtk.CheckButton> ();

    public AAS (HashMap<string,string> parsed_options,
        bool loading_error = false, string loading_error_message = "") {
        Object (
            application_id: "com.github.tomrosen.aas",
            flags: ApplicationFlags.FLAGS_NONE,
            parsed_options: parsed_options,
            loading_error: loading_error,
            loading_error_message: loading_error_message,
            options: new Options (),
            components: new Components (),
            settings: new GLib.Settings ("com.github.tomrosen.aas")
        );
    }
    
    construct {}

    protected override void activate () {
        var main_window = new Gtk.ApplicationWindow (this){
            default_width = 500,
            default_height = 200,
            title = _("Advanced Audio Settings"),
            window_position= Gtk.WindowPosition.CENTER
        };
        
        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();
        
         gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme ==   Granite.Settings.ColorScheme.DARK;
        });
        
        if (settings.get_int ("pos-x") >= 0 && settings.get_int ("pos-y") >= 0) {
            main_window.move (settings.get_int ("pos-x"), settings.get_int ("pos-y"));
        }
        
        main_window.delete_event.connect(()=>{
            int x, y;
            main_window.get_position (out x, out y);
            settings.set_int ("pos-x",x);
            settings.set_int ("pos-y",y);
            return false;
        });
        
        Gtk.Grid grid = new Gtk.Grid () {
            column_spacing = 10,
            row_spacing = 10,
            margin = 20,
            valign = Gtk.Align.START,
            halign = Gtk.Align.CENTER
        };

        if (loading_error) {
            var label_error = new Gtk.Label ("Error while loading:\n" + loading_error_message);
            AASDialog.error (loading_error_message,main_window);
            var error_icon = new Gtk.Image () {
                gicon = new ThemedIcon ("dialog-error"),
                pixel_size = 24
            };
            
            grid.add (error_icon);
            grid.add (label_error);
            
            main_window.add (grid);
            
        } else {
            var button_apply = new Gtk.Button.with_label (_("Apply")) {
                margin_end = 5,
                sensitive= false
            };
            
            button_apply.get_children ().nth_data (0).margin_start = 5;
            button_apply.get_children ().nth_data (0).margin_end = 5;
            
            button_apply.clicked.connect (() => {
                HashMap<string,string> new_config = new HashMap<string,string> ();
                foreach (var box in ui_comboboxes) {
                    new_config.set (box.key,box.value.get_active_id ());
                }
                
                foreach (var check in ui_checkbuttons) {
                    switch (check.key) {
                        case "avoid-resampling":
                            new_config.set (check.key,(!check.value.get_active ()).to_string ());
                            break;
                        default:
                            new_config.set (check.key,check.value.get_active ().to_string ());
                            break;
                    }
                }
                
                bool save_state = AASUtils.write_config (new_config);
                if (save_state) {
                    AASUtils.restart_pulseaudio ();
                    button_apply.sensitive = false;
                    if (settings.get_boolean ("show-info-apply")) {
                        AASDialog.message (
                            _("Some applications may need to be restarted for audio to work again."),
                            main_window);
                    }
                    
                } else {
                    AASDialog.error (_("Something went wrong while writing the config!"),
                        main_window);
                    
                }
            });
            
            var button_reset = new Gtk.Button.with_label (_("Reset default"));
            button_reset.get_children ().nth_data (0).margin_start = 5;
            button_reset.get_children ().nth_data (0).margin_end = 5;
            
            button_reset.clicked.connect (() => {
                GLib.File default_config = GLib.File.new_for_path (AASUtils.get_home_dir () + "/.pulse");
                
                if (default_config.get_child ("daemon.conf.aas.bak").query_exists ()) {
                    default_config = default_config.get_child ("daemon.conf.aas.bak");
                } else {
                    default_config = GLib.File.new_for_path("/etc/pulse/daemon.conf");
                }
                
                string[]? default_config_lines = AASUtils.read_config (default_config);
                HashMap<string,string> default_options = new HashMap<string,string> ();
                
                if (default_config_lines != null) {
                    default_options = AASUtils.parse_config (default_config_lines);
                } else  {
                    critical ("Couldn't load default!");
                }
                
                foreach (var combobox in ui_comboboxes) {
                    combobox.value.set_active_id(default_options.get (combobox.key));
                }
            });
            
            var action_bar = new Gtk.ActionBar () {
                valign = Gtk.Align.END
            };
            
            action_bar.pack_end (button_apply);
            action_bar.pack_end (button_reset);
            
            Gtk.Label label;
            Gtk.ComboBoxText combo_text;
            Gtk.CheckButton check_button;
            
            OptionComponent component;
            HashMap<string,string> option_map;
            string[] option_keys;
            int i = 0;
            
            foreach (var entry in parsed_options.entries) {
                if (components.has_component (entry.key)) {
                    component = components.get_by_key (entry.key);
                    int comp_pos = components.get_component_position (entry.key);
                    
                    switch (component.component_type) {
                        case ComponentType.DROPDOWN:
                            option_map = options.get_by_key (entry.key);
                            option_keys = options.get_key_order (entry.key);
                            label = new Gtk.Label (component.name + ":");
                            combo_text = new Gtk.ComboBoxText (){
                                tooltip_text = component.tooltip,
                            };
                            
                            foreach (string opt_key in option_keys) {
                                combo_text.append (opt_key,option_map.get (opt_key));
                            }
                            
                            if (entry.key == "resample-method") {
                                if (ui_checkbuttons.has_key ("avoid-resampling")) {
                                    combo_text.sensitive = ui_checkbuttons.get (
                                        "avoid-resampling"
                                    ).get_active ();
                                }
                            }
                            
                            combo_text.set_active_id (entry.value);
                            combo_text.changed.connect ( () => {button_apply.sensitive = true;} );
                            grid.attach (label,0,comp_pos,1,1);
                            grid.attach (combo_text,1,comp_pos,7,1);
                            ui_comboboxes.set (entry.key,combo_text);
                            break;
                        case ComponentType.CHECKBOX:
                            label = new Gtk.Label (component.name + ":");
                            check_button = new Gtk.CheckButton ();
                            check_button.set_active (!AASUtils.parse_value_to_bool (entry.value));
                            check_button.toggled.connect (()=>{button_apply.sensitive = true;} );
                            
                            if (entry.key == "avoid-resampling") {
                                check_button.toggled.connect (()=>{ui_comboboxes.get ("resample-method").sensitive = 
                                    check_button.get_active ();} );
                                    
                                if (ui_comboboxes.has_key ("resample-method")) {
                                    ui_comboboxes.get ("resample-method").sensitive = 
                                        check_button.get_active ();
                                }
                            }
                            
                            grid.attach (label,0,comp_pos,1,1);
                            grid.attach (check_button,1,comp_pos,7,1);
                            ui_checkbuttons.set (entry.key,check_button);
                            break;
                        default:
                            break;
                    }
                    
                    i++;
                }
            }
            
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            
            box.pack_start (grid);
            box.pack_end (action_bar);
            main_window.add (box);
        }
        
        main_window.show_all ();
    }

    

    public static int main (string[] args) {
        bool error = false;
        string error_message = "";
        
        GLib.File pulse_conf = GLib.File.new_for_path ("/run/host/etc/pulse/daemon.conf");
        GLib.File pulse_dir = GLib.File.new_for_path (AASUtils.get_home_dir () + "/.pulse");
        
        if (!pulse_conf.query_exists ()) {
            error = true;
            error_message = _("No pulse config file found!");
        }

        if (!pulse_dir.get_parent ().query_exists ()) {
            error = true;
            error_message = _("No home directory set!");
        }
        
        if (!pulse_dir.get_child ("daemon.conf").query_exists ()) {
            AASUtils.copy_from_to (pulse_conf,
                pulse_dir.get_child ("daemon.conf"),true);
        }

        if (!pulse_dir.get_child ("daemon.conf.aas.bak").query_exists ()) {
            AASUtils.copy_from_to (pulse_conf,
                pulse_dir.get_child ("daemon.conf.aas.bak"),true);
        }
        
        string[]? config_lines = AASUtils.read_config (pulse_dir.get_child ("daemon.conf"));
        HashMap<string,string> parsed_options = new HashMap<string,string> ();
        
        if (config_lines != null) {
            parsed_options = AASUtils.parse_config (config_lines);
        } else {
            error = true;
            error_message = _("Couldn't read config file!");
        }

        return new AAS (parsed_options,error,error_message).run (args);
    }


}


