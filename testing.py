import git
import shutil
import os
from git.repo.base import Repo
from git.remote import RemoteProgress
class Progress(RemoteProgress):
    def update(self, *args):
        print(self._cur_line)
path=input('Enter the cloning path with / : \n')  
Repo.clone_from("https://github.com/sky-uk/dta-customer-tf", path,progress=Progress())
print("Cloned the repo")
repo = git.Repo(path)
bn=input('Enter the feature branch name:\n')  
repo.git.checkout('HEAD', b=bn)
print("Local branch created from develop")
repo.git.push('origin', '-u', bn)
print("Branch pushed to remote")
#shutil.rmtree('C:/Users/pparth860/Documents/gittest1')
#print("\n cloned repo deleted")
origin=input('Enter the source path to copy files : \n')  
target=input('Enter the target path in git to drop files : \n')  
files = os.listdir(origin+'\\')
for file_name in files:
   shutil.copy(origin+'\\'+file_name, target+'\\'+file_name)
print("Files are copied successfully")
repo.git.add(all=True)
count_modified_files = len(repo.index.diff(None))
count_staged_files = len(repo.index.diff("HEAD"))
print ('Files staged:',count_modified_files, count_staged_files)
repo.index.commit("4 files committed")
repo.git.push('origin', '-u', bn)
print("changes committed & pushed to remote")