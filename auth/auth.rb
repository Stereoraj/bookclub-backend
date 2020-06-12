# Auth will take care of authentication

require "./core/repositories.rb"
require "./core/errors.rb"
require "bcrypt"
require "date"

def verify_input(username, pw)
  error = nil
  if username.nil? || username.empty?
    raise AuthError.new(400, "Missing `username` in request")
  elsif pw.nil? || pw.empty?
    raise AuthError.new(400, "Missing `password` in request")
  end
  error
end

def verify_registration_input(username, pw, email)
  error = verify_input(username, pw)
  if email.nil? || email.empty?
    raise AuthError.new(400, "Missing `email` in request")
  end
  error
end

def register_user(username, pw, email)
  error = verify_registration_input(username, pw, email)
  return error if error

  user = get_user_from_username(username)
  if user
    raise AuthError.new(409, "User already exists")
  end

  hashed_password = BCrypt::Password.create(pw)
  userdata = {
    username: username,
    hashed_password: hashed_password,
    email: email,
    source: "bookclub",
  }
  user_id = create_user(userdata)
  generate_token(user_id).to_json
end

def verify_user(username, pw)
  error = verify_input(username, pw)
  return error if error

  user = get_user_from_username(username)
  if !user
    raise AuthError.new(404, "User does not exist")
  else
    hashed_password = user["hashed_password"]
    if (BCrypt::Password.new(hashed_password) != pw)
      raise AuthError.new(401, "Incorrect password")
    end
    generate_token(user["id"]).to_json
  end
end

def deactivate_token(access_token)
  if access_token.nil? || access_token.empty?
    raise AuthError.new(400, "Missing `access_token` in Logout Request")
  end

  modified = delete_token(access_token)
  if modified == 0
    raise AuthError.new(404, "Could not delete token: No such token found in database")
  end
end

def verify_token(user_id, access_token)
  token = get_token(user_id, access_token)
  if !token
    raise AuthError.new(401, "Invalid token/user_id combination")
  end

  if Time.now >= token["expiry"]
    raise AuthError.new(401, "Token expired")
  end
end