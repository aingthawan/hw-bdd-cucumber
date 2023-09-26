class MoviesController < ApplicationController
  before_action :force_index_redirect, only: [:index]

  def show
    id = params[:id] # retrieve movie ID from URI route
    @movie = Movie.find(id) # look up movie by unique ID
    # will render app/views/movies/show.<extension> by default
  end

  def index
    @all_ratings = Movie.all_ratings
    @movies = Movie.with_ratings(ratings_list, sort_by)
    @ratings_to_show_hash = ratings_hash
    @sort_by = sort_by
    # remember the correct settings for next time
    session['ratings'] = ratings_list
    session['sort_by'] = @sort_by
  end

  def new
    # default: render 'new' template
  end

  # Copied, for testing
  def search_tmdb
    Tmdb::Search.movie(params[:search_terms])

    # Check if the title parameter is present
    if params[:search_terms].present?
      # Search for movies with the provided title
      search_results = Tmdb::Search.movie(params[:search_terms])

      if search_results.any?
        # Take the first movie from the search results
        movie = search_results.first

        # Assign movie details to instance variables
        @title = movie.title
        @rating = movie.vote_average.to_s
        @release_date = Date.parse(movie.release_date)
        @description = movie.overview
      else
        # Movie not found, sad path
        flash[:error] = "'#{params[:search_terms]}' was not found in TMDb."
        redirect_to movies_path
      end
    else
      flash[:error] = "Please provide a movie title."
      redirect_to movies_path
    end
  end


  def movie_params
    params.require(:movie).permit(:title, :rating, :description, :release_date)
  end

  def create
    @movie = Movie.create!(movie_params)
    flash[:notice] = "#{@movie.title} was successfully created."
    redirect_to movies_path
  end

  # def create
  #   @movie = Movie.create!(params[:movie])
  #   flash[:notice] = "#{@movie.title} was successfully created."
  #   redirect_to movies_path
  # end

  def edit
    @movie = Movie.find params[:id]
  end

  def update
    @movie = Movie.find params[:id]
    @movie.update_attributes!(movie_params)
    flash[:notice] = "#{@movie.title} was successfully updated."
    redirect_to movie_path(@movie)
  end

  def destroy
    @movie = Movie.find(params[:id])
    @movie.destroy
    flash[:notice] = "Movie '#{@movie.title}' deleted."
    redirect_to movies_path
  end

  private

  def force_index_redirect
    if !params.key?(:ratings) || !params.key?(:sort_by)
      flash.keep
      url = movies_path(sort_by: sort_by, ratings: ratings_hash)
      redirect_to url
    end
  end

  def ratings_list
    params[:ratings]&.keys || session[:ratings] || Movie.all_ratings
  end

  def ratings_hash
    Hash[ratings_list.collect { |item| [item, "1"] }]
  end

  def sort_by
    params[:sort_by] || session[:sort_by] || 'id'
  end
end
