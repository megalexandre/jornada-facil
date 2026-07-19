# frozen_string_literal: true

# Steps de registro de ponto (jornada).

Given("que estou autenticado como {string} com senha {string}") do |username, password|
  login_as(username, password)
  expect(token).not_to be_nil,
    "Falha ao autenticar #{username}: #{last_response.code} #{last_response.body}"
end

When("tento abrir uma jornada") do
  @last_response = api.post("/api/v1/journeys", {}, token: token)
end

When("abro uma jornada em latitude {float} e longitude {float}") do |lat, lng|
  @last_response = api.post("/api/v1/journeys", { latitude: lat, longitude: lng }, token: token)
  @journey_id = @last_response.parsed_response["id"] if @last_response.code == 201
end

When("finalizo a jornada em latitude {float} e longitude {float}") do |lat, lng|
  @last_response = api.patch(
    "/api/v1/journeys/#{@journey_id}/finish",
    { latitude: lat, longitude: lng },
    token: token
  )
end

Then("a mensagem de erro é {string}") do |message|
  expect(last_response.parsed_response["error"]).to eq(message)
end

Then("a jornada está aberta") do
  expect(last_response.parsed_response["started_at"]).not_to be_nil
  expect(last_response.parsed_response["finished_at"]).to be_nil
end

Then("a jornada está finalizada") do
  expect(last_response.parsed_response["finished_at"]).not_to be_nil
end
