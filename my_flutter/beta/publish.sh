# tag=$(git symbolic-ref --short -q HEAD)
if [[ $# -lt 1 ]]; then
	echo "请输入分支号，例如：\n\t publish.sh tag"
	exit
fi

tag=$1
productPath="$(pwd)/../../flutter_commercial/.build_ios/*"
targetPath="$(pwd)/workflowTemp"
gitUrl=git@igit.58corp.com:flutter_build_ios/flutter_commercial_build_ios_2.2.2.git

echo $tag
echo $productPath
echo $targetPath

rm -rf $targetPath
git clone $gitUrl --single-branch --depth 1 $targetPath

cd ${targetPath}
find . -not -name .git -depth 1 | xargs rm -rf

cp -rf ${productPath} .

git add .
git commit -m "Workflow Product ${tag}"
git push -u origin master

git tag -a ${tag} -m ${tag}
git push -u origin --tags
rm -rf $targetPath
echo "发布完成"
