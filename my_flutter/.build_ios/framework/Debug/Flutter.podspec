Pod::Spec.new do |s|
  s.name                  = 'Flutter'
  s.version               = '3.0.500' # 3.0.5
  s.summary               = 'A UI toolkit for beautiful and fast apps.'
  s.description           = <<-DESC
Flutter is Google's UI toolkit for building beautiful, fast apps for mobile, web, desktop, and embedded devices from a single codebase.
This pod vends the iOS Flutter engine framework. It is compatible with application frameworks created with this version of the engine and tools.
The pod version matches Flutter version major.minor.(patch * 100) + hotfix.
DESC
  s.homepage              = 'https://flutter.dev'
  s.license               = { :type => 'BSD', :text => <<-LICENSE
Copyright 2014 The Flutter Authors. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of Google Inc. nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

LICENSE
  }
  s.author                = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source                = { :http => 'https://storage.flutter-io.cn/flutter_infra_release/flutter/e85ea0e79c6d894c120cda4ee8ee10fe6745e187/ios/artifacts.zip' }
  s.documentation_url     = 'https://flutter.dev/docs'
  s.platform              = :ios, '9.0'
  s.vendored_frameworks   = 'Flutter.xcframework'
end
