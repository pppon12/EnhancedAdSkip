name: Build

on: [push]

jobs:
  build:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v3
    - name: Install Theos
      run: |
        brew install theos
    - name: Build
      run: |
        cd $THEOS
        make package
    - name: Upload
      uses: actions/upload-artifact@v3
      with:
        name: com.yyy.enhancedadskip
        path: packages/*.deb
