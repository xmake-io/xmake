import os
import sys
import json
import pty
from subprocess import CalledProcessError
class Test:
    def __init__(self):
        self.__task_dict={}
        self.__point_dict={}

    def __run(self,args):
        print(args)
        returncode=pty.spawn(args)
        if returncode!=0:
            raise CalledProcessError(returncode,args)
        print()

    def add_task(self,name,steps):
        self.__task_dict[name]=steps

    def add_point(self,name,opt):
        self.__point_dict[name]=opt

    def get_steps_task_on_point(self,taskname,pointname):
        return [[self.__point_dict[pointname]["project"] if x==None else x for x in step] for step in self.__task_dict[taskname]]

    def run_task_on_point(self,taskname,pointname):
        print("run task `"+taskname+"` on testpoint `"+pointname+"`")
        for step in self.get_steps_task_on_point(taskname,pointname):
            self.__run(step)

    def run_point(self,pointname):
        for task in self.__point_dict[pointname]["tasks"]:
            self.run_task_on_point(task,pointname)

    def run_all(self):
        for point in self.__point_dict:
            self.run_point(point)

    def get_tasks(self):
        return self.__task_dict

    def get_points(self):
        return self.__point_dict

def scan_tests(tester):
    for project in [x for x in os.listdir() if os.path.isdir(x)]:
        opt={
            "project":project,
            "tasks":["generic"],
            "platform":sys.platform
        }
        try:
            with open(os.path.join(project,".test.json"),"r") as f:
                fopt=json.loads(f.read())
                for k,v in fopt.items():
                    opt[k]=v
        except (FileNotFoundError,json.decoder.JSONDecodeError):
            pass
        if opt["platform"]==sys.platform:
            opt["tasks"]=tuple(set([x for x in tester.get_tasks()]).intersection(opt["tasks"]))
            tester.add_point(project,opt)

def scan_tasks(tester):
    try:
        with open(".test.json","r") as f:
            ftsk=json.loads(f.read())
            for k,v in ftsk.items():
                if "platform" not in v or v["platform"]==sys.platform:
                    tester.add_task(k,v["steps"])
    except (FileNotFoundError,json.decoder.JSONDecodeError):
        pass

if __name__=='__main__':
    tester=Test()

    scan_tasks(tester)

    scan_tests(tester)

    tester.run_all()
