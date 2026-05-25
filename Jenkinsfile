// ============================================================
// CropGuard AI — Jenkins CI/CD Pipeline
// Build → Push to ECR → Deploy to K3s → Health Check
// ============================================================

pipeline {
    agent any

    environment {
        AWS_REGION   = 'ap-south-1'
        AWS_ACCOUNT  = '116137269524'
        ECR_REPO     = "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/cropguard-ai"
        IMAGE_TAG    = "${BUILD_NUMBER}"
        KUBECONFIG   = '/var/lib/jenkins/.kube/config'
    }

    stages {

        // ====================================================
        // Stage 1: Checkout code from Git
        // ====================================================
        stage('Checkout') {
            steps {
                checkout scm
                echo "✅ Code checked out — Build #${BUILD_NUMBER}"
            }
        }

        // ====================================================
        // Stage 2: Build Docker image
        // ====================================================
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🔨 Building Docker image..."
                    sh "docker build -t cropguard-ai:${IMAGE_TAG} -t cropguard-ai:latest ."
                    echo "✅ Docker image built: cropguard-ai:${IMAGE_TAG}"
                }
            }
        }

        // ====================================================
        // Stage 3: Push to Amazon ECR
        // Uses IAM Instance Role — no hardcoded credentials!
        // ====================================================
        stage('Push to ECR') {
            steps {
                script {
                    echo "📦 Logging into ECR..."
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    """

                    echo "📤 Tagging and pushing image..."
                    sh """
                        docker tag cropguard-ai:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}
                        docker tag cropguard-ai:latest ${ECR_REPO}:latest
                        docker push ${ECR_REPO}:${IMAGE_TAG}
                        docker push ${ECR_REPO}:latest
                    """

                    echo "✅ Image pushed: ${ECR_REPO}:${IMAGE_TAG}"
                }
            }
        }

        // ====================================================
        // Stage 4: Deploy to K3s (Kubernetes)
        // Jenkins and K3s are on the same machine — no SSH needed!
        // ====================================================
        stage('Deploy to K3s') {
            steps {
                script {
                    echo "🚀 Deploying to Kubernetes..."

                    // Check if deployment exists; if not, apply the manifest
                    def deployExists = sh(
                        script: "kubectl get deployment cropguard-ai --no-headers 2>/dev/null | wc -l",
                        returnStdout: true
                    ).trim()

                    if (deployExists == '0') {
                        echo "📋 First deployment — applying full manifest..."
                        sh """
                            sed 's|IMAGE_PLACEHOLDER|${ECR_REPO}:${IMAGE_TAG}|g' k8s/deployment.yaml | \
                            kubectl apply -f -
                        """
                    } else {
                        echo "🔄 Updating existing deployment..."
                        sh """
                            kubectl set image deployment/cropguard-ai \
                                cropguard-api=${ECR_REPO}:${IMAGE_TAG}
                        """
                    }

                    // Wait for rollout to complete (timeout 5 minutes)
                    echo "⏳ Waiting for rollout..."
                    sh "kubectl rollout status deployment/cropguard-ai --timeout=300s"

                    echo "✅ Deployment successful!"
                }
            }
        }

        // ====================================================
        // Stage 5: Health Check
        // FIX: Service is ClusterIP so localhost won't work.
        // Instead we exec curl INSIDE the running pod itself.
        // ====================================================
        stage('Health Check') {
            steps {
                script {
                    echo "🏥 Running health check..."

                    // Wait for pod to be fully ready
                    sleep(time: 15, unit: 'SECONDS')

                    // Get the name of a running pod
                    def podName = sh(
                        script: "kubectl get pod -l app=cropguard-ai --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null",
                        returnStdout: true
                    ).trim()

                    if (!podName) {
                        error("❌ No running pod found for cropguard-ai. Check: kubectl get pods")
                    }

                    echo "🔍 Checking health on pod: ${podName}"

                    // Run curl inside the pod (bypasses ClusterIP restriction)
                    def response = sh(
                        script: "kubectl exec ${podName} -- curl -sf http://localhost:8000/health",
                        returnStdout: true
                    ).trim()

                    echo "Health check response: ${response}"

                    if (response.contains('"status":"ok"') || response.contains('"status": "ok"')) {
                        echo "✅ Health check PASSED!"
                    } else {
                        echo "⚠️ Pod is running but health response was unexpected: ${response}"
                    }
                }
            }
        }
    }

    // ========================================================
    // Post-build actions
    // ========================================================
    post {
        success {
            echo """
            ========================================
            ✅ CropGuard AI deployed successfully!
            ========================================
            Build:  #${BUILD_NUMBER}
            Image:  ${ECR_REPO}:${IMAGE_TAG}
            ========================================
            """
        }
        failure {
            echo """
            ========================================
            ❌ Deployment FAILED — Build #${BUILD_NUMBER}
            ========================================
            Check the console output above for errors.
            Common fixes:
            - ECR login failed? Check IAM role is attached to EC2.
            - Docker build failed? Check Dockerfile and requirements.
            - K3s deploy failed? Run: kubectl describe pods -l app=cropguard-ai
            - Health check failed? Run: kubectl get pods
            ========================================
            """
        }
        always {
            // Clean up old Docker images to save disk space
            sh "docker image prune -f --filter 'until=24h' || true"
        }
    }
}