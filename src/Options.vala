
using Gee;

public class Options : GLib.Object {
    
    private HashMap<string, HashMap<string,string>> options = 
        new HashMap<string, HashMap<string,string>> ();
        
    private HashMap<string,string> default_sample_format = new HashMap<string,string> ();
    private string[] default_sample_format_order = {};
    
    private HashMap<string,string> default_sample_rate = new HashMap<string,string> ();
    private string [] default_sample_rate_order = {};
    
    private HashMap<string,string> default_sample_channels = new HashMap<string,string> ();
    private string[] default_sample_channels_order = {};
    
    private HashMap<string,string> resample_method = new HashMap<string,string> ();
    private string[] resample_method_order = {};
    
    public Options() {
        Object ();
        
        default_sample_format.set ("u8", "Unsigned 8-bit integer");
        default_sample_format_order += "u8";
        default_sample_format.set ("s16le", "Signed 16-bit integer, Little Endian");
        default_sample_format_order += "s16le";
        default_sample_format.set ("s16be", "Signed 16-bit integer, Big Endian");
        default_sample_format_order += "s16be";
        default_sample_format.set ("s24le", "Signed 24-bit integer, Little Endian");
        default_sample_format_order += "s24le";
        default_sample_format.set ("s24be", "Signed 24-bit integer, Big Endian");
        default_sample_format_order += "s24be";
        default_sample_format.set ("s32le", "Signed 32-bit integer, Little Endian");
        default_sample_format_order += "s32le";
        default_sample_format.set ("s32be", "Signed 32-bit integer, Big Endian");
        default_sample_format_order += "s32be";
        default_sample_format.set ("float32le", "Float 32-bit, Little Endian");
        default_sample_format_order += "float32le";
        default_sample_format.set ("float32be", "Float 32-bit, Big Endian");
        default_sample_format_order += "float32be";
        default_sample_format.set ("s24_32le", "Signed 24-bit integer in LSB of 32-bit word, litle endian");
        default_sample_format_order += "s24_32le";
        default_sample_format.set ("s24_32be", "Signed 24-bit integer in LSB of 32-bit word, big endian");
        default_sample_format_order += "s24_32be";
        default_sample_format.set ("alaw", "8-bit a-Law");
        default_sample_format_order += "alaw";
        default_sample_format.set ("ulaw", "8-bit mu-Law");
        default_sample_format_order += "ulaw";
         
        default_sample_rate.set ("16000", "16000 Hz");
        default_sample_rate_order += "16000";
        default_sample_rate.set ("44100", "44100 Hz");
        default_sample_rate_order += "44100";
        default_sample_rate.set ("48000", "48000 Hz");
        default_sample_rate_order += "48000";
        default_sample_rate.set ("96000", "96000 Hz");
        default_sample_rate_order += "96000";
        default_sample_rate.set ("192000", "192000 Hz");
        default_sample_rate_order += "192000";
        
        default_sample_channels.set ("1","Mono");
        default_sample_channels_order += "1";
        default_sample_channels.set ("2","Stereo");
        default_sample_channels_order += "2";
        
        for (int i = 0; i <= 10; i++) {
            resample_method.set (@"speex-float-$i",@"Speex Float $i");
            resample_method_order += @"speex-float-$i";
        };
        
        for (int i = 0; i <= 10; i++) {
            resample_method.set (@"speex-fixed-$i",@"Speex Fixed $i");
            resample_method_order += @"speex-fixed-$i";
        };
        
        resample_method.set ("trivial", "Trivial");
        resample_method_order += "trivial";
        resample_method.set ("ffmpeg","ffmpeg");
        resample_method_order += "ffmpeg";
        resample_method.set ("auto","auto");
        resample_method_order += "auto";
        resample_method.set ("copy","copy");
        resample_method_order += "copy";
        resample_method.set ("peaks","peaks");
        resample_method_order += "peaks";
        resample_method.set ("soxr-mq","soxr-mq");
        resample_method_order += "soxr-mq";
        resample_method.set ("soxr-hq","soxr-hq");
        resample_method_order += "soxr-hq";
        resample_method.set ("soxr-vhq","soxr-vhq");
        resample_method_order += "soxr-vhq";
        
        options.set ("default-sample-format", default_sample_format);
        options.set ("default-sample-rate", default_sample_rate);
        options.set ("default-sample-channels",default_sample_channels);
        options.set ("resample-method", resample_method);
    }
    
    public HashMap<string,string> get_by_key (string key) {
        return options.get (key);
    }
    
    public string[] get_key_order (string key) {
        string[] order_array = {};
        switch (key) {
            case "default-sample-format":
                order_array = default_sample_format_order;
                break;
            case "default-sample-rate":
                order_array = default_sample_rate_order;
                break;
            case "default-sample-channels":
                order_array = default_sample_channels_order;
                break;
            case "resample-method":
                order_array = resample_method_order;
                break;
        }
        
        return order_array;
    }
    
    public bool has_option (string key) {
        return options.has_key (key);
    }
}

