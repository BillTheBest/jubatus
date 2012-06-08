#include <sstream>
#include <string>
#include <gtest/gtest.h>
#include <pficommon/data/string/utility.h>
#include <pficommon/lang/cast.h>
#include "recommender_mock_storage.hpp"
#include "recommender_mock_util.hpp"

using namespace std;

namespace jubatus {
namespace recommender {

namespace {

void mix(recommender_mock_storage& s1, recommender_mock_storage& s2) {
  string diff, mixed;
  s1.get_diff(diff);
  s2.get_diff(mixed);
  s1.mix(diff, mixed);
  s1.set_mixed_and_clear_diff(mixed);
  s2.set_mixed_and_clear_diff(mixed);
}

}

TEST(recommender_mock_storage, similar_items) {
  const sfv_t query = make_sfv("f1:1 f2:1");
  const vector<pair<string, float> > expect = make_ids("r1:2 r2:1");

  recommender_mock_storage storage;
  storage.set_similar_items(query, expect);

  vector<pair<string, float> > ids;
  storage.similar_items_similarity(query, ids, 2);

  EXPECT_EQ(expect, ids);
}

TEST(recommender_mock_storage, neighbor_items) {
  const sfv_t query = make_sfv("f1:1 f2:1");
  const vector<pair<string, float> > expect = make_ids("r1:1 r2:2");

  recommender_mock_storage storage;
  storage.set_neighbor_items(query, expect);

  vector<pair<string, float> > ids;
  storage.neighbor_items_distance(query, ids, 2);

  EXPECT_EQ(expect, ids);
}

TEST(recommender_mock_storage, similar_items_with_small_ret_num) {
  const sfv_t query = make_sfv("f1:1 f2:1");

  recommender_mock_storage storage;
  storage.set_similar_items(query, make_ids("d1:3 d2:2 d3:1 d4:0.5"));

  vector<pair<string, float> > ids;
  storage.similar_items_similarity(query, ids, 3);

  EXPECT_EQ(make_ids("d1:3 d2:2 d3:1"), ids);
}

TEST(recommender_mock_storage, neighbor_items_with_small_ret_num) {
  const sfv_t query = make_sfv("f1:1 f2:1");

  recommender_mock_storage storage;
  storage.set_neighbor_items(query, make_ids("d1:0.5 d2:1 d3:2 d4:3"));

  vector<pair<string, float> > ids;
  storage.neighbor_items_distance(query, ids, 3);

  EXPECT_EQ(make_ids("d1:0.5 d2:1 d3:2"), ids);
}

TEST(recommender_mock_storage, mix_with_similarity_relation) {
  recommender_mock_storage s1, s2;
  s1.set_similar_items(make_sfv("f1:1"), make_ids("d1:3 d2:2 d3:1"));
  s2.set_similar_items(make_sfv("f2:1"), make_ids("d3:3 d2:2 d1:1"));

  mix(s1, s2);

  vector<pair<string, float> > ids;
  s1.similar_items_similarity(make_sfv("f2:1"), ids, 3);
  EXPECT_EQ(make_ids("d3:3 d2:2 d1:1"), ids);

  s2.similar_items_similarity(make_sfv("f1:1"), ids, 3);
  EXPECT_EQ(make_ids("d1:3 d2:2 d3:1"), ids);
}

TEST(recommender_mock_storage, mix_with_neighbor_relation) {
  recommender_mock_storage s1, s2;
  s1.set_neighbor_items(make_sfv("f1:1"), make_ids("d1:1 d2:2 d3:3"));
  s2.set_neighbor_items(make_sfv("f2:1"), make_ids("d3:1 d2:2 d1:3"));

  mix(s1, s2);

  vector<pair<string, float> > ids;
  s1.neighbor_items_distance(make_sfv("f2:1"), ids, 3);
  EXPECT_EQ(make_ids("d3:1 d2:2 d1:3"), ids);

  s2.neighbor_items_distance(make_sfv("f1:1"), ids, 3);
  EXPECT_EQ(make_ids("d1:1 d2:2 d3:3"), ids);
}

}
}
