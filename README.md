# Agentic Deploy  
**Secure CI/CD Pipeline for LLM-Based Conversational AI Agents on AWS**

Agentic Deploy is a secure, scalable AWS-based deployment pipeline for **LLM-powered conversational agents**.  
It demonstrates best practices in **DevSecOps**, **containerized deployment**, and **AWS-native CI/CD automation**, ensuring that AI agents can be built, deployed, and scaled safely in the cloud.

---

## 🚀 Project Overview

This project implements a **conversational AI weather agent** built using **Strands SDK** and **FastAPI**, deployed securely on AWS using a **defense-in-depth CI/CD pipeline**.  

The architecture focuses on:
- End-to-end **security and automation** using GitHub + AWS CodePipeline
- **Private ECS deployment** with no public IP exposure
- **Internal ALB + API Gateway + VPC Link** for secure communication
- **Secrets encryption** with AWS KMS and Secrets Manager
- **S3 static frontend** served via CloudFront (HTTPS-enabled)

---

## 🏗️ Architecture Overview

<img width="3244" height="2400" alt="CSE 543" src="https://github.com/user-attachments/assets/d172c162-807f-476a-9c2c-dc91321d3d8b" />

### 🔒 Secure Deployment Pipeline

<img width="2051" height="1879" alt="CICD_Arch" src="https://github.com/user-attachments/assets/aa656e33-da7d-4939-813a-dfa0381570be" />

