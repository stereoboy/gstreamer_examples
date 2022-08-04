#include <gst/gst.h>

/* Structure to contain all our information, so we can pass it to callbacks */
typedef struct _CustomData {
    gboolean is_live;
    GstElement *pipeline;
    GstElement *source;
    GstElement *demux;

    // first path
    GstElement *queue0;
    GstElement *rtpjpegdepay0;
    GstElement *jpegdec0;
    GstElement *autovideosink0;
    // second path
    GstElement *queue1;
    GstElement *rtpjpegdepay1;
    GstElement *jpegdec1;
    GstElement *autovideosink1;
} CustomData;

/* Functions below print the Capabilities in a human-friendly format */
static gboolean print_field (GQuark field, const GValue * value, gpointer pfx) {
    gchar *str = gst_value_serialize (value);

    g_print ("%s  %15s: %s\n", (gchar *) pfx, g_quark_to_string (field), str);
    g_free (str);
    return TRUE;
}

static void print_caps (const GstCaps * caps, const gchar * pfx) {
    guint i;

    g_return_if_fail (caps != NULL);

    if (gst_caps_is_any (caps)) {
        g_print ("%sANY\n", pfx);
        return;
    }
    if (gst_caps_is_empty (caps)) {
        g_print ("%sEMPTY\n", pfx);
        return;
    }

    for (i = 0; i < gst_caps_get_size (caps); i++) {
        GstStructure *structure = gst_caps_get_structure (caps, i);

        g_print ("%s%s\n", pfx, gst_structure_get_name (structure));
        gst_structure_foreach (structure, print_field, (gpointer) pfx);
    }
}


/* Handler for the pad-added signal */
static void pad_added_handler (GstElement *src, GstPad *pad, CustomData *data);
static void user_function (GstElement* object,
        guint arg0,
        GstPad* arg1,
        CustomData *data);

static GstCaps *request_pt_map_handler(GstElement* demux,
        guint pt,
        CustomData *data);

static  void new_payload_type_handler(GstElement* object,
        guint arg0,
        GstPad* arg1,
        CustomData *data);

static void payload_type_change_handler (GstElement* demux,
        guint pt,
        CustomData *data);

int main(int argc, char *argv[]) {
    CustomData data;
    GstBus *bus;
    GstMessage *msg;
    GstStateChangeReturn ret;
    gboolean terminate = FALSE;
    GstCaps *caps;

    /* Initialize GStreamer */
    gst_init (&argc, &argv);

    /* Create the elements */
    data.source = gst_element_factory_make ("udpsrc", "source");
    data.demux = gst_element_factory_make ("rtpptdemux", "demux");
    //data.demux = gst_element_factory_make ("rtpssrcdemux", "demux");
    data.queue0 = gst_element_factory_make ("queue", "queue0");
    data.rtpjpegdepay0 = gst_element_factory_make ("rtpjpegdepay", "rtpjpegdepay0");
    data.jpegdec0 = gst_element_factory_make ("jpegdec", "jpegdec0");
    data.autovideosink0 = gst_element_factory_make ("autovideosink", "autovideosink0");

    data.queue1 = gst_element_factory_make ("queue", "queue1");
    data.rtpjpegdepay1 = gst_element_factory_make ("rtpjpegdepay", "rtpjpegdepay1");
    data.jpegdec1 = gst_element_factory_make ("jpegdec", "jpegdec1");
    data.autovideosink1 = gst_element_factory_make ("autovideosink", "autovideosink1");

    /* Create the empty pipeline */
    data.pipeline = gst_pipeline_new ("test-pipeline");

    if (!data.pipeline || !data.source || !data.queue0 || !data.rtpjpegdepay0 || !data.jpegdec0 || !data.autovideosink0 ) {
        g_printerr ("Not all elements could be created.\n");
        return -1;
    }
    if (!data.queue1 || !data.rtpjpegdepay1 || !data.jpegdec1 || !data.autovideosink1 ) {
        g_printerr ("Not all elements could be created.\n");
        return -1;
    }

    /* Build the pipeline. Note that we are NOT linking the source at this
     * point. We will do it later. */
    gst_bin_add_many (GST_BIN (data.pipeline), data.source, data.demux, data.queue0, data.rtpjpegdepay0, data.jpegdec0, data.autovideosink0, NULL);
    gst_bin_add_many (GST_BIN (data.pipeline), data.queue1, data.rtpjpegdepay1, data.jpegdec1, data.autovideosink1, NULL);
    if (!gst_element_link_many (data.source, data.demux, NULL)) {
        g_printerr ("Elements could not be linked.\n");
        gst_object_unref (data.pipeline);
        return -1;
    }
    if (!gst_element_link_many (data.queue0, data.rtpjpegdepay0, data.jpegdec0, data.autovideosink0, NULL)) {
        g_printerr ("Elements could not be linked.\n");
        gst_object_unref (data.pipeline);
        return -1;
    }
    if (!gst_element_link_many (data.queue1, data.rtpjpegdepay1, data.jpegdec1, data.autovideosink1, NULL)) {
        g_printerr ("Elements could not be linked.\n");
        gst_object_unref (data.pipeline);
        return -1;
    }

    /* Set the URI to play */
    g_object_set (data.source, "port", 8554, NULL);
    /* https://stackoverflow.com/questions/20497199/gstreamer-source-code-doesnt-work */
    // TODO caps fixed here??? -> cannot mux differenct media type data??? e.g. video + audio + subtitle???
    caps = gst_caps_new_simple ("application/x-rtp",
//            "encoding-name", G_TYPE_STRING, "JPEG",
//            "media", G_TYPE_STRING, "video",
//            "clock-rate", G_TYPE_INT, 90000,
            NULL);
    print_caps (caps, "      ");
    g_object_set (data.source, "caps", caps, NULL);
    gst_caps_unref(caps);

    /* Connect to the pad-added signal */
    // TODO pad-added vs new-payload-type
    //g_signal_connect (data.demux, "pad-added", G_CALLBACK (pad_added_handler), &data);
    // not necessory
    g_signal_connect (data.demux, "request-pt-map", G_CALLBACK (request_pt_map_handler), &data);
    g_signal_connect (data.demux, "new-payload-type", G_CALLBACK (new_payload_type_handler), &data);
    // not necessory
    //g_signal_connect (data.demux, "payload-type-change", G_CALLBACK (payload_type_change_handler), &data);

    /* Start playing */
    ret = gst_element_set_state (data.pipeline, GST_STATE_PLAYING);
    if (ret == GST_STATE_CHANGE_FAILURE) {
        g_printerr ("Unable to set the pipeline to the playing state.\n");
        gst_object_unref (data.pipeline);
        return -1;
    }

    /* Listen to the bus */
    bus = gst_element_get_bus (data.pipeline);
    do {
        msg = gst_bus_timed_pop_filtered (bus, GST_CLOCK_TIME_NONE,
                GST_MESSAGE_STATE_CHANGED | GST_MESSAGE_ERROR | GST_MESSAGE_EOS | GST_MESSAGE_ANY);

        /* Parse message */
        if (msg != NULL) {
            GError *err;
            gchar *debug_info;

            /*
             * reference: https://gstreamer.freedesktop.org/documentation/gstreamer/gstmessage.html?gi-language=c#GstMessageType
             */
            switch (GST_MESSAGE_TYPE (msg)) {
                case GST_MESSAGE_ERROR:
                    g_print ("GST_MESSAGE_TYPE=%s\n", GST_MESSAGE_TYPE_NAME(msg));
                    gst_message_parse_error (msg, &err, &debug_info);
                    g_printerr ("Error received from element %s: %s\n", GST_OBJECT_NAME (msg->src), err->message);
                    g_printerr ("Debugging information: %s\n", debug_info ? debug_info : "none");
                    g_clear_error (&err);
                    g_free (debug_info);
                    terminate = TRUE;
                    break;
                case GST_MESSAGE_EOS:
                    g_print ("GST_MESSAGE_TYPE=%s\n", GST_MESSAGE_TYPE_NAME(msg));
                    g_print ("End-Of-Stream reached.\n");
                    terminate = TRUE;
                    break;
                case GST_MESSAGE_STATE_CHANGED:
                    g_print ("GST_MESSAGE_TYPE=%s from %s\n", GST_MESSAGE_TYPE_NAME(msg), GST_MESSAGE_SRC_NAME(msg));
                    /* We are only interested in state-changed messages from the pipeline */
                    if (GST_MESSAGE_SRC (msg) == GST_OBJECT (data.pipeline)) {
                        GstState old_state, new_state, pending_state;
                        gst_message_parse_state_changed (msg, &old_state, &new_state, &pending_state);
                        g_print ("Pipeline state changed from %s to %s:\n",
                                gst_element_state_get_name (old_state), gst_element_state_get_name (new_state));
                    } else {
                        GstState old_state, new_state, pending_state;
                        gst_message_parse_state_changed (msg, &old_state, &new_state, &pending_state);
                        g_print ("%s state changed from %s to %s:\n", GST_MESSAGE_SRC_NAME(msg),
                                gst_element_state_get_name (old_state), gst_element_state_get_name (new_state));
                    }
                    break;
                case GST_MESSAGE_NEW_CLOCK:
                    {
                        g_print ("GST_MESSAGE_TYPE=%s from %s\n", GST_MESSAGE_TYPE_NAME(msg), GST_MESSAGE_SRC_NAME(msg));
                        /*
                         * reference: https://cpp.hotexamples.com/examples/-/-/gst_message_parse_new_clock/cpp-gst_message_parse_new_clock-function-examples.html
                         */
                        GstClock *clock;
                        gst_message_parse_new_clock (msg, &clock);
                        g_print ("New clock: %s\n", (clock ? GST_OBJECT_NAME (clock) : "NULL"));
                    }
                    break;
                case GST_MESSAGE_STREAM_STATUS:
                    {
                        g_print ("GST_MESSAGE_TYPE=%s from %s\n", GST_MESSAGE_TYPE_NAME(msg), GST_MESSAGE_SRC_NAME(msg));
                        /*
                         * reference: https://cpp.hotexamples.com/examples/-/-/GST_MESSAGE_TYPE/cpp-gst_message_type-function-examples.html
                         */
                        GstStreamStatusType tp;
                        GstElement * elem = NULL;
                        gst_message_parse_stream_status(msg, &tp, &elem);
                        g_print("stream status: elem %s, %i\n", GST_ELEMENT_NAME(elem), tp);
                    }
                    break;
                case GST_MESSAGE_STREAM_START:
                    {
                        g_print ("GST_MESSAGE_TYPE=%s from %s\n", GST_MESSAGE_TYPE_NAME(msg), GST_MESSAGE_SRC_NAME(msg));
                    }
                    break;
                case GST_MESSAGE_ELEMENT:
                    {
                        g_print ("GST_MESSAGE_TYPE=%s from %s\n", GST_MESSAGE_TYPE_NAME(msg), GST_MESSAGE_SRC_NAME(msg));
                        g_print(">>> %s\n", gst_structure_get_name (gst_message_get_structure(msg)));
                    }
                    break;
                default:
                    /* We should not reach here */
                    //g_printerr ("Unexpected message received (%d).\n", GST_MESSAGE_TYPE (msg));
                    g_print ("GST_MESSAGE_TYPE=%s from %s\n", GST_MESSAGE_TYPE_NAME(msg), GST_MESSAGE_SRC_NAME(msg));
                    break;
            }
            gst_message_unref (msg);
        } else {
            g_print("....");
        }
    } while (!terminate);

    /* Free resources */
    gst_object_unref (bus);
    gst_element_set_state (data.pipeline, GST_STATE_NULL);
    gst_object_unref (data.pipeline);
    return 0;
}

/* This function will be called by the pad-added signal */
static void pad_added_handler (GstElement *src, GstPad *new_pad, CustomData *data) {

    return;
}

GstCaps *request_pt_map_handler(GstElement* demux,
        guint pt,
        CustomData *data)
{
    g_print ("%s:%d(%s, %d, data)\n", __func__, __LINE__, GST_OBJECT_NAME(demux), pt);
    GstCaps *caps = gst_caps_new_simple ("application/x-rtp",
            "encoding-name", G_TYPE_STRING, "JPEG",
            "media", G_TYPE_STRING, "video",
            "clock-rate", G_TYPE_INT, 90000,
            NULL);
    return caps;
//    return NULL;
}

void new_payload_type_handler(GstElement* src,
        guint pt,
        GstPad* new_pad,
        CustomData *data)
{
    g_print ("%s:%d\n", __func__, __LINE__);
    g_print ("Received new pyload type (%d, %s).\n", pt, GST_ELEMENT_NAME (new_pad));
    GstPad *sink_pad0 = gst_element_get_static_pad (data->queue0, "sink");
    GstPad *sink_pad1 = gst_element_get_static_pad (data->queue1, "sink");
    GstPadLinkReturn ret;
    GstCaps *new_pad_caps = NULL;
    GstStructure *new_pad_struct = NULL;
    const gchar *new_pad_type = NULL;

    g_print ("Received new pad '%s' from '%s':\n", GST_PAD_NAME (new_pad), GST_ELEMENT_NAME (src));

    /* Check the new pad's type */
    new_pad_caps = gst_pad_get_current_caps (new_pad);
    if (!new_pad_caps) {
        g_print ("No new_pad_caps\n");
    }
    print_caps (new_pad_caps, "      ");
    new_pad_struct = gst_caps_get_structure (new_pad_caps, 0);
    new_pad_type = gst_structure_get_name (new_pad_struct);
    g_print("new_pad_type: %s\n", new_pad_type);
    if (pt == 26) {
        if (gst_pad_is_linked (sink_pad0)) {
            g_print ("We are already linked. Ignoring.\n");
            goto exit;
        }
        /* Attempt the link */
        ret = gst_pad_link (new_pad, sink_pad0);
        if (GST_PAD_LINK_FAILED (ret)) {
            g_print ("Type is '%s' but link failed.\n", new_pad_type);
        } else {
            g_print ("Link succeeded (type '%s').\n", new_pad_type);
        }
    } else if (pt == 96) {
        if (gst_pad_is_linked (sink_pad1)) {
            g_print ("We are already linked. Ignoring.\n");
            goto exit;
        }
        /* Attempt the link */
        ret = gst_pad_link (new_pad, sink_pad1);
        if (GST_PAD_LINK_FAILED (ret)) {
            g_print ("Type is '%s' but link failed.\n", new_pad_type);
        } else {
            g_print ("Link succeeded (type '%s').\n", new_pad_type);
        }
    } else {
        g_print ("It has type '%s' which is not application/x-rtp. Ignoring.\n", new_pad_type);
        goto exit;
    }

exit:
    /* Unreference the new pad's caps, if we got them */
    if (new_pad_caps != NULL)
        gst_caps_unref (new_pad_caps);

    /* Unreference the sink pad */
    gst_object_unref (sink_pad0);
    gst_object_unref (sink_pad1);
    return;
}

void payload_type_change_handler(GstElement* demux,
        guint pt,
        CustomData *data)
{
    g_print ("%s:%d(%s, %d, data)\n", __func__, __LINE__, GST_OBJECT_NAME(demux), pt);
    return;
}

