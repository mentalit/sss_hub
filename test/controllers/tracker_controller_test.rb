require "test_helper"

class TrackerControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get tracker_new_url
    assert_response :success
  end

  test "should get create" do
    get tracker_create_url
    assert_response :success
  end
end
