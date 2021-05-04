#!/usr//bin/env python

import sys, re 
import json, click
import subprocess
import inquirer

sub = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx"
rg = "xxxx-rg"
rsv = "xxx-storage-vault"
loc = "australiaxxx"

sub = click.prompt("Input the Azure subscription: ", default=sub)
rg = click.prompt("Input the vault's resource group: ", default=rg)
rsv = click.prompt("Input the backup vault: ", default=rsv)
loc = click.prompt("Input the location: ", default=loc)

opts = []

try:
  j = subprocess.check_output(['az', 'backup', 'item', 'list', '--resource-group', rg, '--vault-name', rsv])
  d = json.loads(j)
  for i in d:
    # 2020-11-06: still working 
    n = i["properties"]["friendlyName"]
    opts.append(n)
except ValueError as e:
  print "Error: ", e

if not opts:
    sys.exit("No VMs found in vault")

opts.append("Exit")

def vm2(vm):
  d = re.findall("\d{2}$", vm);
  if d:
    d = int(d[0])
    d += 1
    d = "%02d" % d;
    vm = re.sub(r"\d{2}$", d, vm);
  else:
    vm = vm + '-02';
  return vm;

def main():

    questions = [
    inquirer.List(
        'action_tag',
        message="Choose the VM for restoration: ",
        choices=opts,
        ),
    ]
    answers = inquirer.prompt(questions)
    action = answers["action_tag"]
    if action == "Exit":
        answer = None
        while answer not in ("yes", "no"):
            #answer = input("Enter yes or no: ")
            answer = raw_input("Enter yes or no to continue [Y/N]? ").lower()
            if answer == "y":
                print ("%s\n" % action )
                break ;
            elif answer == "n":
                print ("do nothing ...quit ...")
                break ;
            else:
                print("Please enter yes or no.")

    else:
      vm = vm2(action)
      val = "vm=%s vm2=%s rg=%s rsv=%s loc=%s sub=%s" % (action, vm, rg, rsv, loc, sub)
      cmd = "time ansible-playbook -i hosts playbook.yml -e '%s'" % val
      with open('test.log', 'w') as f:  # replace 'w' with 'wb' for Python 3
        process = subprocess.Popen(str(cmd), stdout=subprocess.PIPE, shell=True)
        for c in iter(lambda: process.stdout.read(1), ''):  # replace '' with b'' for Python 3
          sys.stdout.write(c)
          f.write(c)

if __name__ == '__main__':
    main()

