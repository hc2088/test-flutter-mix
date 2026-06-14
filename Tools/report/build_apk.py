def prepare_framework():
    import os   
    import subprocess
    current_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), '../dreame_framework')
    commands = [
        ['svn', 'cleanup'],
        ['svn', 'revert', '-R', '.'],
        ['svn', 'up']
    ]
    
    for cmd in commands:
        try:
            subprocess.run(cmd, cwd=current_dir, check=True)
            print(f"Successfully executed: {' '.join(cmd)}")
        except subprocess.CalledProcessError as e:
            print(f"Error executing {' '.join(cmd)}: {e}")
            raise

def build_apk():
    import os
    os.environ['CUSTOM_WORKSPACE'] = '/Users/xiangkan/honey_chat/dreame_jenkins/worksapce/build_nook_apk'
    os.environ['FLUTTER_PATH'] = '/Users/xiangkan/honey_chat/dreame_jenkins/flutter_3.32.8/bin/flutter'
    os.environ['DART_PATH'] = '/Users/xiangkan/honey_chat/dreame_jenkins/flutter_3.32.8/bin/dart'
    from dreame_framework.nook.build_nook_apk import BuildNookAPK
    import time

    branch='master' # master
    appVersion='1.1.0'
    appServer='development' # development productioninnertest
    appChannel='androiddev' # androidofficial androiddev
    feishuUrl='nook_members' # all_members only_you no_msg nook_members

    build = BuildNookAPK(branch=branch, 
                    appVersion=appVersion, 
                    time_stamp=time.time(),
                    appChannel=appChannel,
                    appServer=appServer,
                    debug=False, 
                    feishuUrl=feishuUrl)
    build.env_prepare()
    build.build()
    build.upload()

prepare_framework()
build_apk()
