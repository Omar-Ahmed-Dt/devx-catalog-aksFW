// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go github.com/external-secrets/external-secrets/apis/generators/v1alpha1

package v1alpha1

import (
	"github.com/external-secrets/external-secrets/apis/externalsecrets/v1beta1"
	smmeta "github.com/external-secrets/external-secrets/apis/meta/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// ACRAccessTokenSpec defines how to generate the access token
// e.g. how to authenticate and which registry to use.
// see: https://github.com/Azure/acr/blob/main/docs/AAD-OAuth.md#overview
#ACRAccessTokenSpec: {
	auth: #ACRAuth @go(Auth)

	// TenantID configures the Azure Tenant to send requests to. Required for ServicePrincipal auth type.
	tenantId?: string @go(TenantID)

	// the domain name of the ACR registry
	// e.g. foobarexample.azurecr.io
	registry: string @go(ACRRegistry)

	// Define the scope for the access token, e.g. pull/push access for a repository.
	// if not provided it will return a refresh token that has full scope.
	// Note: you need to pin it down to the repository level, there is no wildcard available.
	//
	// examples:
	// repository:my-repository:pull,push
	// repository:my-repository:pull
	//
	// see docs for details: https://docs.docker.com/registry/spec/auth/scope/
	// +optional
	scope?: string @go(Scope)

	// EnvironmentType specifies the Azure cloud environment endpoints to use for
	// connecting and authenticating with Azure. By default it points to the public cloud AAD endpoint.
	// The following endpoints are available, also see here: https://github.com/Azure/go-autorest/blob/main/autorest/azure/environments.go#L152
	// PublicCloud, USGovernmentCloud, ChinaCloud, GermanCloud
	// +kubebuilder:default=PublicCloud
	environmentType?: v1beta1.#AzureEnvironmentType @go(EnvironmentType)
}

#ACRAuth: {
	// ServicePrincipal uses Azure Service Principal credentials to authenticate with Azure.
	// +optional
	servicePrincipal?: null | #AzureACRServicePrincipalAuth @go(ServicePrincipal,*AzureACRServicePrincipalAuth)

	// ManagedIdentity uses Azure Managed Identity to authenticate with Azure.
	// +optional
	managedIdentity?: null | #AzureACRManagedIdentityAuth @go(ManagedIdentity,*AzureACRManagedIdentityAuth)

	// WorkloadIdentity uses Azure Workload Identity to authenticate with Azure.
	// +optional
	workloadIdentity?: null | #AzureACRWorkloadIdentityAuth @go(WorkloadIdentity,*AzureACRWorkloadIdentityAuth)
}

#AzureACRServicePrincipalAuth: {
	secretRef: #AzureACRServicePrincipalAuthSecretRef @go(SecretRef)
}

#AzureACRManagedIdentityAuth: {
	// If multiple Managed Identity is assigned to the pod, you can select the one to be used
	identityId?: string @go(IdentityID)
}

#AzureACRWorkloadIdentityAuth: {
	// ServiceAccountRef specified the service account
	// that should be used when authenticating with WorkloadIdentity.
	// +optional
	serviceAccountRef?: null | smmeta.#ServiceAccountSelector @go(ServiceAccountRef,*smmeta.ServiceAccountSelector)
}

// Configuration used to authenticate with Azure using static
// credentials stored in a Kind=Secret.
#AzureACRServicePrincipalAuthSecretRef: {
	// The Azure clientId of the service principle used for authentication.
	clientId?: smmeta.#SecretKeySelector @go(ClientID)

	// The Azure ClientSecret of the service principle used for authentication.
	clientSecret?: smmeta.#SecretKeySelector @go(ClientSecret)
}

// ACRAccessToken returns a Azure Container Registry token
// that can be used for pushing/pulling images.
// Note: by default it will return an ACR Refresh Token with full access
// (depending on the identity).
// This can be scoped down to the repository level using .spec.scope.
// In case scope is defined it will return an ACR Access Token.
//
// See docs: https://github.com/Azure/acr/blob/main/docs/AAD-OAuth.md
//
// +kubebuilder:object:root=true
// +kubebuilder:storageversion
// +kubebuilder:subresource:status
// +kubebuilder:resource:scope=Namespaced,categories={acraccesstoken},shortName=acraccesstoken
#ACRAccessToken: {
	metav1.#TypeMeta
	metadata?: metav1.#ObjectMeta  @go(ObjectMeta)
	spec?:     #ACRAccessTokenSpec @go(Spec)
}

// ACRAccessTokenList contains a list of ExternalSecret resources.
#ACRAccessTokenList: {
	metav1.#TypeMeta
	metadata?: metav1.#ListMeta @go(ListMeta)
	items: [...#ACRAccessToken] @go(Items,[]ACRAccessToken)
}
