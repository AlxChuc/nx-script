#!/usr/bin/env node

const { stat, realpath, readFile } = require('fs/promises')
const { exec } = require('child_process');
const readLine = require('readline');

const interface = readLine.createInterface({
    input: process.stdin,
    output: process.stdout
});

async function getAnswer(message) { // temporal
    return new Promise(resolve => {
        interface.question(message, answer => {
            resolve(answer);
        });
    }, err => {});
}

async function getProjects() {
    let projects;
    
    try {
        const path = await realpath('.', { encoding: 'utf-8' });
        const isNx = await stat(`${path}/nx.json`)
        if (!isNx) throw new Error('It\'s not a Nx workspace.');

        const data = await readFile(`${path}/workspace.json`, { encoding: 'utf-8' });
        const json = JSON.parse(data)
        
        if (typeof json === 'object'
        && json && 'projects' in json
        && typeof json.projects === 'object'
        && json.projects) {
            projects = Object.keys(json.projects).map(key => {
                const project = json.projects[key];

                if (typeof project === 'object'
                && project && 'targets' in project && typeof project.targets === 'object'
                && project.targets
                ) {
                    return { project: key, targets: Object.keys(project.targets) };
                }

                return undefined;
            }).filter(v => !!v);
        }
    } catch (error) {
        console.log(error?.message);
    }

    return projects;
}

function runProjectTarget(project, target) {
    const command = `npx nx run ${project}:${target}`;
    console.log(`Running '${command}'`);
    return exec(command, (err, stdout, stderr) => {
        if (err) console.log(err);
        if (stdout) console.log(stdout);
        if (stderr) console.log(stderr);
    })
}

async function workspace() {
    const projects = await getProjects();

    if (!projects) return

    let selectedProject, selectedTarget;
    const listProjects = projects.map((project, i) => `${i + 1}: ${project.project}`);

    while(!selectedProject) {
        const answer = await getAnswer('Select a project:\n' + listProjects.join('\n') + '\n# ');
        if (!isNaN(Number(answer))) {
            selectedProject = Number(answer) - 1;
        }
    }

    if (!projects[selectedProject]) return

    const listTargets = projects[selectedProject].targets.map((target, i) => `${i + 1}: ${target}`);

    while(!selectedTarget) {
        const answer = await getAnswer('Select target:\n' + listTargets.join('\n') + '\n# ');
        if (!isNaN(Number(answer))) {
            selectedTarget = Number(answer) - 1;
        }
    }

    if (!projects[selectedProject].targets[selectedTarget]) return

    runProjectTarget(projects[selectedProject].project, projects[selectedProject].targets[selectedTarget]);
}

workspace()
