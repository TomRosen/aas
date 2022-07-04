using Gee;

namespace AASUtils {

    string get_home_dir () {
        return GLib.Environment.get_home_dir ();
    }

    void create_dir (GLib.File path, bool with_parents = false) {
        try {

            if (path.query_exists ()) {
                return;
            }

            if (with_parents) {
                path.make_directory_with_parents (null);
            } else {
                path.make_directory (null);
            }

            return;
        } catch (Error e) {
            critical ("Error: %s\n", e.message);
            return;
        }
    }
    
    void copy_from_to (GLib.File from, GLib.File to, bool upsert_dir = false) {
        
        if (!from.query_exists ()){
            message ("from path does not exist\n");
            return;
        }

        if (upsert_dir) {
            if (from.query_file_type (0) == FileType.DIRECTORY) {
                create_dir (to,true);
            } else {
                create_dir (to.get_parent (),true);
            }
        }

        try {
            from.copy (to,0,null);
            return;
        } catch (Error e) {
            critical ("Error: %s\n", e.message);
            return;
        }
    }

    void parse_line (string str, out string key, out string value) {
    
        string line = str.strip ();
            
        if (line == null) {
            key = "";
            value = "";
            return;
        }

        if (line.length == 0) {
            key = "";
            value = "";
            return;
        }

        if (line.has_prefix ('#'.to_string ())) {
            key = "";
            value = "";
            return;
        }
        
        int pos = line.index_of ("=", 0);
        
        if (line.has_prefix (';'.to_string ())) {
            key = line.substring (1, pos - 1).strip () ?? "";
        } else {
            key = line.substring (0, pos).strip () ?? "";
        }
        
        value = line.substring (pos + 1, 
            line.substring (pos + 1).index_of (" ") - (pos + 1))
            .strip () ?? "";
    }

    HashMap<string,string> parse_config (string[] lines) {
        HashMap<string,string> parsed_options = new HashMap<string,string> ();
        
        foreach (string line in lines) {
            string key = "";
            string value = "";
            parse_line (line, out key, out value);
            if ( key != "" && value != "") {
                parsed_options.set (key,value);
            }
        }
        
        return parsed_options;
    }
    
    string[]? read_config (GLib.File config_file) {
        
        string[] lines = {};
    
        if (!config_file.query_exists ()) {
            return null;
        }
        
        try {
            var dis = new DataInputStream (config_file.read ());
            string line;
            while ((line = dis.read_line (null)) != null) {
                lines += line;
            }
            
        } catch (Error e) {
            critical ("%s", e.message);
            return null;
        }
        
        return lines;
    }
    
    string parse_out (string value, string config_value) {
        string output = value;
        switch (value) {
            case "true":
                if (config_value == "yes" || config_value == "no") {
                    output = "yes";
                }
                
                break;
            case "false":
                if (config_value == "yes" || config_value == "no") {
                    output = "no";
                }
                
                break;
        }
        
        return output;
    }
    
    bool write_config (HashMap<string,string> new_data) {
        GLib.File config_file = GLib.File.new_for_path (AASUtils.get_home_dir () + "/.pulse");
        
        if (config_file.get_child ("daemon.conf").query_exists ()) {
            config_file = config_file.get_child ("daemon.conf");
        } else if (config_file.get_child ("daemon.conf.aas.bak").query_exists ()) {
            config_file = config_file.get_child ("daemon.conf.aas.bak");
        } else {
            config_file = GLib.File.new_for_path ("/etc/pulse/daemon.conf");
        }
        
        string[]? config_lines = read_config (config_file);
        if (config_lines == null) {
            return false;
        }
        
        ArrayList<string> saved_data = new ArrayList<string> ();
        int index = 0;
        foreach (string line in config_lines) {
            string key = "";
            string value = "";
            parse_line (line, out key,out value);
            if (new_data.has_key (key)) {
                config_lines[index] = @"$key = $(parse_out (new_data.get (key),value))";
                saved_data.add (key);
            }
            
            index++;
        }
        
        if (new_data.size != saved_data.size) {
            foreach (var entry in new_data) {
                if (!saved_data.contains (entry.key)) {
                    message ("Add line!");
                    config_lines += @"$(entry.key) = $(new_data.get (entry.key))";
                }
            }
        }
        
        try {
            config_file = GLib.File.new_for_path (AASUtils.get_home_dir () + "/.pulse/daemon.conf");
            if (config_file.query_exists ()) {
                config_file.delete ();
            }
            
            var dos = new DataOutputStream (config_file.create (FileCreateFlags.REPLACE_DESTINATION));
            foreach (string line in config_lines) {
                dos.put_string (line + "\n");
            }
            
            return true;
        } catch (Error e) {
            critical (e.message);
            return false;
        }
    }
    
    bool parse_value_to_bool (string value) {
        bool bool_value = false;
        switch (value) {
            case "yes":
                bool_value = true;
                break;
            case "true":
                bool_value = true;
                break;
            case "no":
                bool_value = false;
                break;
            case "false":
                bool_value = false;
                break;
        }
        
        return bool_value;
    }
    
    void restart_pulseaudio () {
        Posix.system ("systemctl --user restart pulseaudio.socket");
        Posix.system ("systemctl --user restart pulseaudio.service");
    }
}


