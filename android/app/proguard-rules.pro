# ML Kit (google_mlkit_translation) builds its components by instantiating
# each ComponentRegistrar reflectively at startup. R8 sees no direct callers
# of the constructors and strips them, so RemoteModelManager is never
# registered and the plugin crashes while attaching to the engine.
-keep class * implements com.google.firebase.components.ComponentRegistrar {
    public <init>();
}
