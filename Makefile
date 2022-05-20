default:
	mdbook serve --port 3001

build:
	mdbook build

deploy:
	-rm -rf ./docs ./_build
	mdbook build
	mv ./_build ./docs
	-rm -rf ./docs/.git

zip:
	-rm -rf ./kusion-in-action-book
	-rm ./kusion-in-action-book.zip

	mdbook build -d kusion-in-action-book

	rm -rf ./kusion-in-action-book/.git

	rm ./kusion-in-action-book/.gitignore

	zip -r kusion-in-action-book.zip kusion-in-action-book
	-rm -rf ./kusion-in-action-book

clean:
	-rm -rf ./_build ./docs
	-rm *.zip
