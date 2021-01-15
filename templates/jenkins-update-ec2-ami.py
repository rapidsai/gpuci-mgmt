#!/usr/bin/python

import requests
import os
import sys

jenkins_base_url = os.environ['JENKINS_URL']
jenkins_auth_user = os.environ['JENKINS_AUTH_USER']
jenkins_auth_password = os.environ['JENKINS_AUTH_PASSWORD']
jenkins_crumb_name = ""
jenkins_crumb_value = ""
# shared session required to use crumbs
jenkins_session = requests.Session()
verify_ssl = True
# three amis generated from packer build job
gpu_ami_amd64 = os.getenv("GPU_AMI_AMD64")
cpu_ami_amd64 = os.getenv("CPU_AMI_AMD64")
cpu_ami_arm64 = os.getenv("CPU_AMI_ARM64")

def get_crumb_url():
    request_url = jenkins_base_url.replace('https://', '');
    if not request_url.endswith('/'):
        request_url = f'{request_url}/'
    return f'https://{jenkins_auth_user}:{jenkins_auth_password}@{request_url}crumbIssuer/api/json'

def get_jenkins_crumb():
    global jenkins_crumb_name
    global jenkins_crumb_value

    if jenkins_crumb_value:
        return jenkins_crumb_value

    crumb_url = get_crumb_url()
    r = jenkins_session.get(crumb_url, verify=verify_ssl)
    jenkins_crumb_name = r.json()["crumbRequestField"]
    jenkins_crumb_value = r.json()["crumb"]
    return jenkins_crumb_value

def get_groovy_url():
    groovy_url = jenkins_base_url.replace('https://', '');
    if not groovy_url.endswith('/'):
        groovy_url = f'{groovy_url}/'
    return f'https://{jenkins_auth_user}:{jenkins_auth_password}@{groovy_url}scriptText'

def update_jenkins_ami_id(cpu_ami_amd64, cpu_ami_arm64, gpu_ami_amd64):
    groovy_url = get_groovy_url()
    groovy_script = """
        import hudson.plugins.ec2.AmazonEC2Cloud

        def is_arm(instance_class) {
            arm_classes = ['m6g', 'c6g', 'r6g', 'a1']
            for (klazz in arm_classes) {
                if (instance_class.toLowerCase().contains(klazz))return true
            }
            return false
        }


        Jenkins.instance.clouds.each { cloud ->
            if (cloud instanceof AmazonEC2Cloud) {
                cloud.getTemplates().each { agent ->
                    if (agent.getDisplayName().toLowerCase().contains("cpu")) {
                        agent.setAmi("%s")
                        if (is_arm(agent.type.toString())) agent.setAmi('%s')    
                    }
                    if (agent.getDisplayName().toLowerCase().contains("gpu")) agent.setAmi("%s")
                }
            }
        }
        Jenkins.instance.save()

        println "yes"
        """ % (cpu_ami_amd64, cpu_ami_arm64, gpu_ami_amd64)
    payload = {'script': groovy_script, jenkins_crumb_name: jenkins_crumb_value}
    headers = {jenkins_crumb_name: jenkins_crumb_value}
    r = jenkins_session.post(groovy_url, verify=verify_ssl, data=payload, headers=headers)
    if not r.status_code == 200:
        print(f'HTTP POST to Jenkins URL {groovy_url} resulted in {r.status_code}')
        print(r.headers)
        print(r.text)
        sys.exit(1)

    if not r.text.strip() == "yes":
        print(r.text)
        return False
    
    return True

def main():
    get_jenkins_crumb()

    assert "ami" in cpu_ami_amd64
    assert "ami" in cpu_ami_arm64
    assert "ami" in gpu_ami_amd64

    update_success = update_jenkins_ami_id(cpu_ami_amd64, cpu_ami_arm64, gpu_ami_amd64)

    if update_success:
        print("Jenkins AMI has been updated.")
    else:
        print("Ran into an error when attempting to update the Jenkins AMI ID")

        sys.exit(1)


if __name__ == '__main__':
    main()
