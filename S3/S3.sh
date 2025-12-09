#!/bin/bash
# =====================================================
# AWS S3 AUTOMATION SCRIPT (Fully Documented)
# Author: Zaher
# Purpose: Automate key AWS S3 operations via CLI
# =====================================================

# ---------------------------------------------------------------------
# 1️⃣ Create a new S3 bucket
# ---------------------------------------------------------------------
# The command below creates a new S3 bucket named "test-zaher-s3-bucket".
# --region specifies the AWS region (us-east-1 in this case).
# NOTE: In regions other than us-east-1, you must add "--create-bucket-configuration LocationConstraint=<region>"
aws s3api create-bucket --bucket test-zaher-s3-bucket --region us-east-1


# ---------------------------------------------------------------------
# 2️⃣ List all existing S3 buckets
# ---------------------------------------------------------------------
# Displays a list of all buckets under your AWS account.
# It helps confirm that your new bucket was successfully created.
aws s3 ls


# ---------------------------------------------------------------------
# 3️⃣ Upload an object (file) to the S3 bucket
# ---------------------------------------------------------------------
# --bucket specifies the target bucket name.
# --key specifies the "object key", i.e., the path or name inside S3 (like a virtual file path).
# --body specifies the local file path to upload.
# When you upload, S3 automatically assigns ownership to the *uploader* (you), not the bucket owner (important for ACLs later).
aws s3api put-object --bucket test-zaher-s3-bucket --key images/zaher.jpg --body "/mnt/c/Users/Dell/OneDrive/Desktop/zaher.jpg"


# ---------------------------------------------------------------------
# 4️⃣ Delete an object from the S3 bucket
# ---------------------------------------------------------------------
# Removes the object specified by the key. The bucket must exist.
# You might use this when cleaning up files before deleting the bucket.
aws s3api delete-object --bucket test-zaher-s3-bucket --key images/zaher.jpg


# ---------------------------------------------------------------------
# 5️⃣ Delete the Public Access Block configuration
# ---------------------------------------------------------------------
# By default, AWS blocks *all* public access to new buckets.
# This means you can’t assign public ACLs or make objects public.
# This command removes that restriction, allowing ACLs to be applied.
aws s3api delete-public-access-block --bucket test-zaher-s3-bucket


# ---------------------------------------------------------------------
# 6️⃣ (Optional) Reapply a strict Public Access Block on another bucket
# ---------------------------------------------------------------------
# This command re-enables all 4 public access block settings for another bucket.
# It's useful when you want to make a bucket *completely private* again.
aws s3api put-public-access-block --bucket devops90-cli-bucket \
--public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"


# ---------------------------------------------------------------------
# 7️⃣ Check the current ownership control settings
# ---------------------------------------------------------------------
# This retrieves the bucket's current ownership settings.
# Ownership controls determine who “owns” uploaded objects.
aws s3api get-bucket-ownership-controls --bucket test-zaher-s3-bucket


# ---------------------------------------------------------------------
# 🧠 EXPLANATION: Ownership Control & ACL Relationship
# ---------------------------------------------------------------------
# When you create a new S3 bucket, AWS (by default) enforces "BucketOwnerEnforced" mode.
# This setting DISABLES all ACLs — meaning you can’t use `put-object-acl` to make objects public.
#
# There are 3 Object Ownership modes:
#  1. **BucketOwnerEnforced (default)** → ACLs disabled, only bucket policies apply.
#  2. **BucketOwnerPreferred** → The bucket owner owns new objects even if others upload them.
#  3. **ObjectWriter** → The uploader (object writer) owns their uploaded object.
#
# To enable ACLs again (so you can use public-read), you must switch from
# "BucketOwnerEnforced" ➜ "ObjectWriter" (this re-enables ACL functionality).


# ---------------------------------------------------------------------
# 8️⃣ Change the Object Ownership setting
# ---------------------------------------------------------------------
# This changes the ownership mode to ObjectWriter so ACLs can be used.
# Without this, you’ll get an error like:
# “AccessControlListNotSupported: The bucket does not allow ACLs”
aws s3api put-bucket-ownership-controls --bucket test-zaher-s3-bucket \
--ownership-controls="Rules=[{ObjectOwnership=ObjectWriter}]"


# ---------------------------------------------------------------------
# 9️⃣ Set object ACL (Access Control List) - Method 1
# ---------------------------------------------------------------------
# Grants public read access using the ACL system.
# --grant-read allows everyone (AllUsers group) to read the object via public URL.
# URI explanation: http://acs.amazonaws.com/groups/global/AllUsers = the global public group.
aws s3api put-object-acl --bucket test-zaher-s3-bucket --key zaher.jpg \
--grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers


# ---------------------------------------------------------------------
# 🔟 Set object ACL (simplified) - Method 2
# ---------------------------------------------------------------------
# Same as above, but easier syntax: directly sets the ACL to public-read.
# Once this is applied, anyone can access the object through its S3 public URL.
aws s3api put-object-acl --bucket test-zaher-s3-bucket --key zaher.jpg --acl public-read


# ---------------------------------------------------------------------
# ⚙️ ACL EXPLANATION (Access Control List)
# ---------------------------------------------------------------------
# ACLs are legacy permission mechanisms for S3.
# They allow fine-grained control at the object level (who can read/write specific files).
# However, AWS recommends using **Bucket Policies** instead for modern setups.
#
# Common ACLs:
#  - private → Only owner has access
#  - public-read → Anyone can view (GET)
#  - public-read-write → Anyone can view and upload (not safe)
#
# ⚠️ If your bucket uses "BucketOwnerEnforced", these ACLs will be IGNORED entirely.


# ---------------------------------------------------------------------
# 1️⃣1️⃣ Delete the S3 bucket
# ---------------------------------------------------------------------
# Deletes the bucket completely. You must first remove all objects inside it.
# If any files remain, this operation will fail.
aws s3api delete-bucket --bucket test-zaher-s3-bucket


# 🧩 Command 1️⃣2️⃣:
# Apply a bucket policy that allows access only from a **specific domain**.
# 
# 🔹 The `put-bucket-policy` command sets or replaces the bucket's access policy.
# 🔹 The `--bucket` flag specifies which bucket we’re applying the policy to.
# 🔹 The `--policy` flag specifies the file containing the JSON policy.
#
# In this case:
# - `Allow_Specific_Domain_policy.json` contains a JSON policy 
#   that restricts access to requests coming from a certain domain (e.g., example.com)
#
# Example structure inside Allow_Specific_Domain_policy.json:
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": "*",
#       "Action": "s3:GetObject",
#       "Resource": "arn:aws:s3:::test-zaher-s3-bucket/*",
#       "Condition": {
#         "StringLike": {
#           "aws:Referer": "https://example.com/*"
#         }
#       }
#     }
#   ]
# }
#
aws s3api put-bucket-policy --bucket test-zaher-s3-bucket --policy file://Allow_Specific_Domain_policy.json


# 🧩 Command 1️⃣3️⃣ :
# Apply a bucket policy that allows access only from a **specific IP address**.
#
# 🔹 Same command as above, but with a different JSON policy file.
# 🔹 The file `Allow_Specific_ip_policy.json` defines an IP-based restriction.
#
# Example structure inside Allow_Specific_ip_policy.json:
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": "*",
#       "Action": "s3:GetObject",
#       "Resource": "arn:aws:s3:::test-zaher-s3-bucket/*",
#       "Condition": {
#         "IpAddress": {
#           "aws:SourceIp": "203.0.113.25/32"
#         }
#       }
#     }
#   ]
# }
#
# This means only requests coming from IP 203.0.113.25 
# can access objects inside the bucket.
#
aws s3api put-bucket-policy --bucket test-zaher-s3-bucket --policy file://Allow_Specific_ip_policy.json
