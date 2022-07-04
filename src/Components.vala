using Gee;

public enum ComponentType {
    DROPDOWN,
    CHECKBOX
}

public class OptionComponent : GLib.Object {
    public ComponentType component_type {get; construct;}
    public string name {get; construct;}
    public string tooltip {get; construct;}
    public bool sensitive {get; construct;}

    public OptionComponent (ComponentType component_type, string name, 
        string tooltip = "", bool sensitive = true) {
       Object (
           name: name,
           component_type: component_type,
           tooltip: tooltip,
           sensitive: sensitive
       );
    }
}

public class Components : GLib.Object {

     private HashMap<string, OptionComponent> components = 
         new HashMap<string, OptionComponent> ();
    private string[] component_order = {};
         
     private OptionComponent default_sample_format = new OptionComponent (
        ComponentType.DROPDOWN,
        _("Format"),
        _("Set the default format!"),
        true
        );
        
    private OptionComponent default_sample_rate = new OptionComponent (
       ComponentType.DROPDOWN,
       _("Rate"),
       _("Set the default samplerate!"),
       true
       );
       
    private OptionComponent default_sample_channels = new OptionComponent (
        ComponentType.DROPDOWN,
        _("Channels"),
        _("Select the channels!"),
        true
    );
    
    private OptionComponent resample_method = new OptionComponent (
        ComponentType.DROPDOWN,
        _("Resample Method"),
        _("Select the resample method!"),
        true
    );
    
    private OptionComponent avoid_resampling = new OptionComponent (
        ComponentType.CHECKBOX,
        _("Enable Resampling"),
        _("Turn on/off resampling!"),
        true
    );
         
     public Components () {
         Object ();
         
         components.set ("default-sample-format", default_sample_format);
         components.set ("default-sample-rate", default_sample_rate);
         components.set ("default-sample-channels", default_sample_channels);
         components.set ("resample-method", resample_method);
         components.set ("avoid-resampling", avoid_resampling);
         
         component_order = {
             "default-sample-rate",
             "default-sample-format",
             "default-sample-channels",
             "avoid-resampling",
             "resample-method"
         };
         
     }
     
     public OptionComponent get_by_key (string key) {
         return components.get (key);
     }
     
     public bool has_component (string key)  {
         return components.has_key (key);
     }
     
     public int get_component_position (string key) {
         int index = -1;
         for (int i = 0; i < component_order.length; i++) {
             if (component_order[i] == key) {
                 index = i;
                 break;
             }
         }
         
         return index;
     }
}


