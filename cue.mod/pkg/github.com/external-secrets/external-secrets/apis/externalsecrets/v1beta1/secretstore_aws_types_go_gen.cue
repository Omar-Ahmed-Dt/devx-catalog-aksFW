// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go github.com/external-secrets/external-secrets/apis/externalsecrets/v1beta1

package v1beta1

import esmeta "github.com/external-secrets/external-secrets/apis/meta/v1"

// AWSAuth tells the controller how to do authentication with aws.
// Only one of secretRef or jwt can be specified.
// if none is specified the controller will load credentials using the aws sdk defaults.
#AWSAuth: {
	// +optional
	secretRef?: null | #AWSAuthSecretRef @go(SecretRef,*AWSAuthSecretRef)

	// +optional
	jwt?: null | #AWSJWTAuth @go(JWTAuth,*AWSJWTAuth)
}

// AWSAuthSecretRef holds secret references for AWS credentials
// both AccessKeyID and SecretAccessKey must be defined in order to properly authenticate.
#AWSAuthSecretRef: {
	// The AccessKeyID is used for authentication
	accessKeyIDSecretRef?: esmeta.#SecretKeySelector @go(AccessKeyID)

	// The SecretAccessKey is used for authentication
	secretAccessKeySecretRef?: esmeta.#SecretKeySelector @go(SecretAccessKey)

	// The SessionToken used for authentication
	// This must be defined if AccessKeyID and SecretAccessKey are temporary credentials
	// see: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_use-resources.html
	// +Optional
	sessionTokenSecretRef?: null | esmeta.#SecretKeySelector @go(SessionToken,*esmeta.SecretKeySelector)
}

// Authenticate against AWS using service account tokens.
#AWSJWTAuth: {
	serviceAccountRef?: null | esmeta.#ServiceAccountSelector @go(ServiceAccountRef,*esmeta.ServiceAccountSelector)
}

// AWSServiceType is a enum that defines the service/API that is used to fetch the secrets.
// +kubebuilder:validation:Enum=SecretsManager;ParameterStore
#AWSServiceType: string // #enumAWSServiceType

#enumAWSServiceType:
	#AWSServiceSecretsManager |
	#AWSServiceParameterStore

// AWSServiceSecretsManager is the AWS SecretsManager service.
// see: https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html
#AWSServiceSecretsManager: #AWSServiceType & "SecretsManager"

// AWSServiceParameterStore is the AWS SystemsManager ParameterStore service.
// see: https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html
#AWSServiceParameterStore: #AWSServiceType & "ParameterStore"

// SecretsManager defines how the provider behaves when interacting with AWS
// SecretsManager. Some of these settings are only applicable to controlling how
// secrets are deleted, and hence only apply to PushSecret (and only when
// deletionPolicy is set to Delete).
#SecretsManager: {
	// Specifies whether to delete the secret without any recovery window. You
	// can't use both this parameter and RecoveryWindowInDays in the same call.
	// If you don't use either, then by default Secrets Manager uses a 30 day
	// recovery window.
	// see: https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_DeleteSecret.html#SecretsManager-DeleteSecret-request-ForceDeleteWithoutRecovery
	// +optional
	forceDeleteWithoutRecovery?: bool @go(ForceDeleteWithoutRecovery)

	// The number of days from 7 to 30 that Secrets Manager waits before
	// permanently deleting the secret. You can't use both this parameter and
	// ForceDeleteWithoutRecovery in the same call. If you don't use either,
	// then by default Secrets Manager uses a 30 day recovery window.
	// see: https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_DeleteSecret.html#SecretsManager-DeleteSecret-request-RecoveryWindowInDays
	// +optional
	recoveryWindowInDays?: int64 @go(RecoveryWindowInDays)
}

#Tag: {
	key:   string @go(Key)
	value: string @go(Value)
}

// AWSProvider configures a store to sync secrets with AWS.
#AWSProvider: {
	// Service defines which service should be used to fetch the secrets
	service: #AWSServiceType @go(Service)

	// Auth defines the information necessary to authenticate against AWS
	// if not set aws sdk will infer credentials from your environment
	// see: https://docs.aws.amazon.com/sdk-for-go/v1/developer-guide/configuring-sdk.html#specifying-credentials
	// +optional
	auth?: #AWSAuth @go(Auth)

	// Role is a Role ARN which the provider will assume
	// +optional
	role?: string @go(Role)

	// AWS Region to be used for the provider
	region: string @go(Region)

	// AdditionalRoles is a chained list of Role ARNs which the provider will sequentially assume before assuming the Role
	// +optional
	additionalRoles?: [...string] @go(AdditionalRoles,[]string)

	// AWS External ID set on assumed IAM roles
	externalID?: string @go(ExternalID)

	// AWS STS assume role session tags
	// +optional
	sessionTags?: [...null | #Tag] @go(SessionTags,[]*Tag)

	// SecretsManager defines how the provider behaves when interacting with AWS SecretsManager
	// +optional
	secretsManager?: null | #SecretsManager @go(SecretsManager,*SecretsManager)

	// AWS STS assume role transitive session tags. Required when multiple rules are used with the provider
	// +optional
	transitiveTagKeys?: [...null | string] @go(TransitiveTagKeys,[]*string)
}
