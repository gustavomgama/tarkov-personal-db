# Bootsnap Configuration
# Optimized for production performance

if Rails.env.production?
  # Use default compiler (do not override compiler_selector)
  # Bootsnap 1.25+ handles this automatically
end

# Disable in test for faster boot
if Rails.env.test?
  Bootsnap.setup(
    cache_dir: "tmp/cache/bootsnap",
    development_mode: false,
    load_path_cache: false,
    compile_cache_iseq: false,
    compile_cache_yaml: false
  )
end
