# frozen_string_literal: true

require "rspec"

describe XxxRename::SiteClients::EvilAngel do
  include_context "config provider"

  subject { described_class.new }

  describe ".search" do
    let(:scene_data) do
      XxxRename::Data::SceneData.new(
        { female_actors: ["Bridgette B"],
          male_actors: ["Lexington Steele"],
          actors: ["Bridgette B", "Lexington Steele"],
          collection: "Evilangel",
          collection_tag: "EA",
          title: "Lex's Breast Fest, Scene #03",
          id: "59022",
          date_released: Time.parse("2013-09-15"),
          director: "Lexington Steele",
          description: "Incredibly buxom Latina bombshell Bridgette B. calls up director Lexington Steele for some hot interracial action. They talk dirty on the phone as Bridgette caresses her voluptuous body. In no time, Lex arrives at Bridgette's house, and the glamorous slut unleashes his massive black cock for some oral worship. She gags on his enormous member and slides the shaft between her mountainous mammaries. Lex plows her tender cunt on the kitchen countertop; moving to the sofa, Bridgette rides his gigantic ebony rod, her plump butt cheeks wobbling up and down. Finally, Lexington creams all over Bridgette's face and chest.", # rubocop:disable Layout/LineLength
          scene_link: "https://www.evilangel.com/en/video/evilangel/lexs-breast-fest-scene-03/59022",
          scene_cover: "https://transform.gammacdn.com/21798/21798_03/previews/2/128/top_1_resized/21798_03_01.jpg",
          movie: { name: "Lex's Breast Fest",
                   date: Time.parse("2013-07-26"),
                   url: "https://www.evilangel.com/en/movie/Lexs-Breast-Fest/21798",
                   front_image: "https://transform.gammacdn.com/movies/21798/21798_lexs_breast_fest_front_400x625.jpg?width=900&height=1272&format=webp",
                   back_image: "https://transform.gammacdn.com/movies/21798/21798_lexs_breast_fest_back_400x625.jpg?width=900&height=1272&format=webp",
                   studio: "Evilangel",
                   synopsis: "Legendary ebony cocksman Lexington Steele is an accomplished director with a deep attraction for buxom sluts. And the super-stacked bombshells in 'Lex's Breast Fest,' the stud filmmaker's latest boob-centric interracial masterpiece, are positively top-heavy with talent! In five sizzling scenes of hard-core boob worship and fucking, Lex's creative libido and enormous black cock tame his voluptuous vixens ... and ultimately shower them with his hot, creamy sperm. First up are dark-haired Sophie Dee and blonde bombshell Krissy Lynn, a pair of shapely lesbians worshiping one another's massive mammaries; Lex joins in, and Krissy and Sophie slide his throbbing fuck pole between their glistening jugs. They ride him to orgasm, with Krissy taking a thorough anal pounding. Next, big-boobed brunette bombshell Jayden Jaymes releases Lex's huge black cock and lovingly licks it like a lollipop until he fucks her silly. Incredibly busty Latina glamazon Bridgette B. calls up Lex for some phone sex, and soon welcomes the director into her kitchen for a hot interracial house call that leaves the curvaceous wench sore but satisfied. Tanned, curvy bombshell Richelle Ryan shows up late for her audition. At first he's pissed, but when Lex sees the sassy slut's enormous hooters bursting from her sequined bikini top, he loses all professional detachment. Lastly, globe-breasted porn slut Angelina Valentine gives Lex a nasty lap dance; she grinds on his lap and gets royally fucked until he splatters her whore face with jism. 'Lex's Breast Fest' is endowed with behind-the-scenes interviews on the DVD." } } # rubocop:disable Layout/LineLength
      )
    end

    context "given an unprocessed file" do
      let(:file) { "LexsBreastFest_s03_LexingtonSteele_BridgetteB_540p.mp4" }
      let(:parsed_scene_data) do
        # to ensure we use whatever matcher parses
        match = XxxRename::SiteClientMatcher.new.match(file)
        match.find { |x| x.site_client.instance_of?(described_class) }&.parsed_scene_data
      end
      let(:unprocessed) { true }

      before do
        VCR.use_cassette("evil_angel_client/lexs_breast_fest_scene_03_unprocessed") do
          @result = subject.search(file, parsed_scene_data: parsed_scene_data, unprocessed: unprocessed)
        end
      end

      it "returns the expected response" do
        expect(parsed_scene_data).not_to be_nil
        expect(@result).to eq_scene_data(scene_data)
      end
    end

    context "given a processed file" do
      let(:file) { "Lex's Breast Fest, Scene 03 [EA] Lex's Breast Fest [F] Bridgette B [M] Lexington Steele.mp4" }
      let(:parsed_scene_data) do
        XxxRename::Data::ParsedSceneData.new(
          title: "Lex's Breast Fest, Scene 03",
          female_actors: ["Bridgette B"],
          male_actors: ["Lexington Steele"],
          collection: "Lex's Breast Fest"
        )
      end
      let(:unprocessed) { false }

      before do
        VCR.use_cassette("evil_angel_client/lexs_breast_fest_scene_03_processed") do
          @result = subject.search(file, parsed_scene_data: parsed_scene_data, unprocessed: unprocessed)
        end
      end

      it { expect(@result).to eq_scene_data(scene_data) }
    end
  end

  describe ".actor_details" do
    context "when actor is Bridgette B." do
      let(:actor) { "Bridgette B." }
      let(:expected_name) { "Bridgette B" }
      let(:expected_gender) { "female" }

      before do
        VCR.use_cassette("evil_angel_client/actor_details/bridgette_b_dot") do
          @result = subject.actor_details(actor)
        end
      end

      it_behaves_like "a successful actor matcher"
    end

    context "when actor is Bridgette B" do
      let(:actor) { "Bridgette B" }
      let(:expected_name) { "Bridgette B" }
      let(:expected_gender) { "female" }

      before do
        VCR.use_cassette("evil_angel_client/actor_details/bridgette_b") do
          @result = subject.actor_details(actor)
        end
      end

      it_behaves_like "a successful actor matcher"
    end

    context "when actor is Tommy Gunn" do
      let(:actor) { "Tommy Gunn" }
      let(:expected_name) { "Tommy Gunn" }
      let(:expected_gender) { "male" }

      before do
        VCR.use_cassette("evil_angel_client/actor_details/tommy_gunn") do
          @result = subject.actor_details(actor)
        end
      end

      it_behaves_like "a successful actor matcher"
    end
  end
end
