{
  'targets': [
    {
      'target_name': 'capnp',
      'sources': ['src/node-capnp/capnp.cc'],
      'cflags_cc': ['-std=c++17'],
      'cflags_cc!': ['-fno-rtti', '-fno-exceptions'],
      'include_dirs': [
        'src',
        '<!(node -e "require(\'nan\')")'
      ],
      'conditions': [
        [ 'OS=="mac"', {
          # TODO: Does this condition actually get picked up when we're cross-compiling to Darwin?
          # Experimenting with Win32 cross-compilation suggests `OS` is still set to `linux`.

          'xcode_settings': {
            'OTHER_CPLUSPLUSFLAGS' : ['-std=c++14','-stdlib=libc++'],
            'OTHER_LDFLAGS': ['-stdlib=libc++'],
            'GCC_ENABLE_CPP_RTTI': 'YES',
            'GCC_ENABLE_CPP_EXCEPTIONS': 'YES',
            'MACOSX_DEPLOYMENT_TARGET': '10.7'
          },

          # Dynamic linking
          'libraries': [
            '-lkj', '-lkj-async', '-lcapnp', '-lcapnpc', '-lcapnp-rpc',
          ]
        }],
        [ 'OS!="mac"', {

          # Static linking
          'libraries': [
            '-Wl,--whole-archive',
            '../build-capnp/.libs/libkj.a',
            '../build-capnp/.libs/libkj-async.a',
            '../build-capnp/.libs/libcapnp.a',
            '../build-capnp/.libs/libcapnpc.a',
            '../build-capnp/.libs/libcapnp-rpc.a',
            '-Wl,--no-whole-archive',
          ],
        }],
      ],
      
    }
  ]
}
