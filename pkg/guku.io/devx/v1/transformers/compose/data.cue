package compose

import (
	"guku.io/devx/v1"
	"guku.io/devx/v1/traits"
)

// add a compose service for a database
#AddDatabase: v1.#Transformer & {
	traits.#Database
	$metadata: _
	$dependencies: [...string]

	database: {
		host:     "\($metadata.id)"
		username: string | *"root"
		password: string | *"password"
	}

	$resources: compose: #Compose & {
		services: "\($metadata.id)": {
			if database.engine == "postgres" {
				image: "postgres:\(database.version)-alpine"
			}
			ports: [
				"\(database.port)",
			]
			if database.persistent {
				if database.engine == "postgres" {
					volumes: ["\($metadata.id)-data:/var/lib/postgresql/data"]
				}
			}

			if database.engine == "postgres" {
				environment: {
					POSTGRES_USER:     database.username
					POSTGRES_PASSWORD: database.password
					POSTGRES_DB:       database.database
				}
			}

			depends_on: [
				for id in $dependencies if services[id] != _|_ {id},
			]
			restart: "no"
		}
		if database.persistent {
			volumes: "\($metadata.id)-data": null
		}
	}
}

// add a compose service for kafka
#AddKafka: v1.#Transformer & {
	traits.#Kafka
	$metadata: _
	$dependencies: [...string]

	kafka: {
		name: string | *$metadata.id
		brokers: count: 1
		bootstrapServers: "\(kafka.name)-kafka:9096"
	}

	$resources: compose: #Compose & {
		volumes: "\(kafka.name)-kafka-config": null

		services: {
			"\(kafka.name)-zookeeper": {
				image: "confluentinc/cp-zookeeper:3.3.1"
				depends_on: [
					"\(kafka.name)-config-files",
					for id in $dependencies if services[id] != _|_ {id},
				]
				ports: [
					"2181:2181",
				]
				environment: {
					ZOOKEEPER_CLIENT_PORT: 2181
					ZOOKEEPER_TICK_TIME:   2000
					KAFKA_OPTS:            "-Djava.security.auth.login.config=/etc/config/zookeeper.jaas.conf -Dzookeeper.authProvider.1=org.apache.zookeeper.server.auth.SASLAuthenticationProvider -Dzookeeper.allowSaslFailedClients=false -Dzookeeper.requireClientAuthScheme=sasl"
				}
				volumes: [
					"\(kafka.name)-kafka-config:/etc/config",
				]
			}

			"\(kafka.name)-broker": {
				image: "confluentinc/cp-kafka:3.3.1"
				depends_on: [
					"\(kafka.name)-config-files",
					for id in $dependencies if services[id] != _|_ {id},
				]
				ports: [
					"9092:9092",
					"29092:29092",
				]
				environment: {
					KAFKA_BROKER_ID:                            1
					KAFKA_ZOOKEEPER_CONNECT:                    "\(kafka.name)-zookeeper:2181"
					KAFKA_LISTENERS:                            "SASL_PLAINTEXT://:9092"
					KAFKA_LISTENER_SECURITY_PROTOCOL_MAP:       "SASL_PLAINTEXT:SASL_PLAINTEXT"
					KAFKA_ADVERTISED_LISTENERS:                 "SASL_PLAINTEXT://\(kafka.name)-broker:9092"
					KAFKA_SASL_ENABLED_MECHANISMS:              "SCRAM-SHA-256"
					KAFKA_SASL_MECHANISM_INTER_BROKER_PROTOCOL: "SCRAM-SHA-256"
					KAFKA_INTER_BROKER_LISTENER_NAME:           "SASL_PLAINTEXT"
					KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR:     1
					KAFKA_OPTS:                                 "-Djava.security.auth.login.config=/etc/config/kafka.jaas.conf"
				}
				volumes: [
					"\(kafka.name)-kafka-config:/etc/config",
				]
			}

			"\(kafka.name)-add-kafka-users": {
				image: "confluentinc/cp-kafka:3.3.1"
				depends_on: [
					"\(kafka.name)-zookeeper",
					"\(kafka.name)-config-files",
					for id in $dependencies if services[id] != _|_ {id},
				]
				command: [
					"/bin/bash",
					"-c",
					"cub zk-ready \(kafka.name)-zookeeper:2181 120",
					"&&",
					"kafka-configs --zookeeper \(kafka.name)-zookeeper:2181 --alter --add-config 'SCRAM-SHA-256=[iterations=4096,password=broker]' --entity-type users --entity-name broker",
				]
				environment: {
					KAFKA_BROKER_ID:         "ignored"
					KAFKA_ZOOKEEPER_CONNECT: "ignored"
					KAFKA_OPTS:              "-Djava.security.auth.login.config=/etc/kafka/kafka.jaas.conf"
				}
				volumes: [
					"\(kafka.name)-kafka-config:/etc/kafka",
				]
			}

			"\(kafka.name)-config-files": {
				image: "alpine:3.14"
				depends_on: [
					for id in $dependencies if services[id] != _|_ {id},
				]
				command: [
					"/bin/sh",
					"-c",
					"""
						    cat > /etc/config/kafka.jaas.conf <<EOL
						    KafkaServer {
						        org.apache.kafka.common.security.scram.ScramLoginModule required
						        username=\"broker\"
						        password=\"broker\";
						    };
						    Client {
						        org.apache.zookeeper.server.auth.DigestLoginModule required
						        username=\"kafka\"
						        password=\"kafka\";
						    };
						    EOL
						    cat > /etc/config/zookeeper.jaas.conf <<EOL
						    Server {
						        org.apache.zookeeper.server.auth.DigestLoginModule required
						        user_kafka=\"kafka\";
						    };
						    EOL
						""",
				]
				volumes: ["\(kafka.name)-kafka-config:/etc/config"]
			}
		}
	}
}

#AddKafkaUser: v1.#Transformer & {
	traits.#Kafka
	traits.#Secret
	kafka:     _
	secrets:   _
	$metadata: _
	$resources: compose: #Compose & {
		services: "\(kafka.name)-add-kafka-users": command: [
			string,
			string,
			string,
			string,
			for _, secret in secrets {
				"&& kafka-configs --zookeeper \(kafka.name)-zookeeper:2181 --alter --add-config 'SCRAM-SHA-256=[iterations=4096,password=\(secret.name)]' --entity-type users --entity-name \(secret.name)"
			},
		]
	}
}
