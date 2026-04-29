pipeline {
  agent {
    kubernetes {
      yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:debug
      imagePullPolicy: IfNotPresent
      command: ["/busybox/cat"]
      tty: true
    - name: git
      image: alpine/git:latest
      command: ["cat"]
      tty: true
'''
    }
  }

  options {
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  environment {
    REGISTRY   = 'kind-registry:5000'
    IMAGE_REPO = 'lw-idp/sample-nginx'
  }

  stages {
    // Skip the entire pipeline when the head commit is one of our own
    // chart-bump commits. SCM-side messageExclusion is deprecated for
    // Pipeline jobs (the git plugin warns and silently ignores it),
    // so we gate inside the Jenkinsfile instead. Without this gate
    // every successful build pushes a bump commit which the SCM poller
    // sees as a real change → next build → next bump → infinite loop.
    stage('Skip if bump commit') {
      steps {
        script {
          def msg = sh(returnStdout: true, script: 'git log -1 --pretty=%B').trim()
          if (msg.startsWith('chore: bump image.tag')) {
            echo "Bump commit detected (${msg.split('\n')[0]}) — skipping CI."
            env.SKIP_BUILD = 'true'
          } else {
            env.SKIP_BUILD = 'false'
          }
        }
      }
    }

    stage('Compute tag') {
      when { expression { return env.SKIP_BUILD != 'true' } }
      steps {
        script {
          env.SHORT_SHA = (env.GIT_COMMIT ?: '').take(7) ?: env.BUILD_NUMBER
          env.IMAGE_TAG = env.SHORT_SHA
          echo "Building tag ${env.IMAGE_TAG}"
        }
      }
    }

    stage('Stamp html with SHA') {
      when { expression { return env.SKIP_BUILD != 'true' } }
      steps {
        sh 'sed -i "s/__BUILD_SHA__/${SHORT_SHA}/" html/index.html'
      }
    }

    stage('Build & push image') {
      when { expression { return env.SKIP_BUILD != 'true' } }
      steps {
        container('kaniko') {
          sh '''
            /kaniko/executor \
              --dockerfile=Dockerfile \
              --context=. \
              --destination=${REGISTRY}/${IMAGE_REPO}:${IMAGE_TAG} \
              --insecure --skip-tls-verify
          '''
        }
      }
    }

    stage('Bump chart tag and push') {
      when { expression { return env.SKIP_BUILD != 'true' } }
      steps {
        container('git') {
          withCredentials([string(credentialsId: 'github-pat', variable: 'GITHUB_PAT')]) {
            // alpine/git's default WORKDIR is /git, so `cd` into the
            // workspace explicitly before running git. Also mark the
            // workspace as a safe directory — when the SCM checkout was
            // done by jnlp under a different uid, git in this container
            // can refuse with "dubious ownership" otherwise.
            sh '''
              set -eu
              cd "${WORKSPACE}"
              git config --global --add safe.directory "${WORKSPACE}"
              git config user.email jenkins@lw-idp.local
              git config user.name  jenkins
              git fetch origin main
              git checkout main
              git reset --hard origin/main
              sed -i "s|^  tag:.*|  tag: \"${IMAGE_TAG}\"|" chart/values.yaml
              git add chart/values.yaml
              if git diff --cached --quiet ; then
                echo "no tag change — skipping push"
                exit 0
              fi
              git commit -m "chore: bump image.tag to ${IMAGE_TAG} [skip ci]"
              git push https://x-access-token:${GITHUB_PAT}@github.com/abhikk30/idp-sample-nginx.git HEAD:main
            '''
          }
        }
      }
    }
  }
}
