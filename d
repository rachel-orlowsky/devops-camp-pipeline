Skip to content
khaledAFS
/
sample-files
Public
Code
Issues
Pull requests
Actions
Projects
Security
Insights
sample-files/post_improving_pipeline_lab/devops-camp-db-jenkinsfile
@khaledAFS
khaledAFS Update devops-camp-db-jenkinsfile
 History
 1 contributor
79 lines (79 sloc)  3.46 KB
pipeline {
    agent {
        label 'jenkins-agent'
    }
    environment {
        PIPELINE_HASH = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        HARBOR_REGISTRY = 'harbor.dev.afsmtddso.com'
        HARBOR_PROJECT = 'kawwad-harbor-project'
        DB_IMAGE_NAME = 'db'
    }
    stages {
        //TODO: add stages to pipeline
        stage('Application repository') {
            steps {
                echo "Cloning application repository"
                sh 'git clone https://github.com/khaledAFS/afs-labs-student.git'
                dir('afs-labs-student') {
                    script {
                        env.COMMIT_HASH = sh(script: 'git log --format=format:%h -1 --follow database/database.sql', returnStdout: true).trim()
                    }
                }
                withCredentials([usernamePassword(credentialsId: 'kawwad-harbor-auth', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    script {
                        env.BUILD_DB = sh(script: 'python check_harbor_db.py -h $COMMIT_HASH -i $DB_IMAGE_NAME -r $HARBOR_REGISTRY -p $HARBOR_PROJECT -c ${USERNAME}:${PASSWORD}', returnStdout: true).trim()
                    }
                }
            }
        }
        stage('DB changes: true') {
           when {
              environment name: 'BUILD_DB', value: 'true'
           }
           stages {
              stage('Database docker build') {
                  steps {
                      echo "Building database image"
                      //TODO: build docker image & push to Harbor
                      withCredentials([usernameColonPassword(credentialsId: 'kawwad-harbor-auth', variable: 'HARBOR-AUTH')]) {
                          script {
                              docker.build('$DB_IMAGE_NAME-$COMMIT_HASH', '-f ./db/Dockerfile ./afs-labs-student')
                              docker.withRegistry('https://$HARBOR_REGISTRY', 'kawwad-harbor-auth') {
                                  sh 'docker tag $DB_IMAGE_NAME-$COMMIT_HASH $HARBOR_REGISTRY/$HARBOR_PROJECT/$DB_IMAGE_NAME:$COMMIT_HASH-$PIPELINE_HASH'
                                  sh 'docker push $HARBOR_REGISTRY/$HARBOR_PROJECT/$DB_IMAGE_NAME:$COMMIT_HASH-$PIPELINE_HASH'
                              }
                          }
                      }
                  }
                  post {
                      //TODO: clean local docker images
                      always {
                          echo "Clean local $DB_IMAGE_NAME image"
                          script {
                              try {
                                  sh 'docker rmi $DB_IMAGE_NAME-$COMMIT_HASH:latest'
                                  sh 'docker rmi $HARBOR_REGISTRY/$HARBOR_PROJECT/$DB_IMAGE_NAME:$COMMIT_HASH-$PIPELINE_HASH'
                              } catch (err) {
                                  echo err.getMessage()
                              }
                          }
                      }
                  }
              }
              stage('Deploy') {
                  steps {
                      echo "Deployment stage"
                      //TODO: deploy database
                      sh 'kubectl -n kawwad set image deployment/db-deployment db-deployment=$HARBOR_REGISTRY/$HARBOR_PROJECT/$DB_IMAGE_NAME:$COMMIT_HASH-$PIPELINE_HASH'
                  }
              }
           }
        }
    }
    post {
        cleanup {
            echo "Clean workspace"
            sh 'rm -rf .git ./*'
        }
    }
}
Footer
© 2023 GitHub, Inc.
Footer navigation
Terms
Privacy
Security
Status
Docs
Contact GitHub
Pricing
API
Training
Blog
About
sample-files/devops-camp-db-jenkinsfile at main · khaledAFS/sample-files